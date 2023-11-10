const std = @import("std");
const File = std.fs.File;
const Self = @This();
const vv = @import("ast.zig");
const ast = @import("ast.zig").ast;
const node = @import("ast.zig").Node;
const tokenizer = @import("lexer.zig").Tokenizer;
const types = @import("ast.zig").Types;
const token = @import("lexer.zig").Token;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub const Parser = struct {
    tokens_: std.ArrayList(token),
    current: token,
    allocator: std.mem.Allocator,
    token_i: usize,
    token_kinds: []const token.Kind,
    source: []const u8,
    file_name: []const u8,
    ast: ast,

    const Error = error{
        invalid_token,
        expected_simicolon,
    };

    pub fn init(source: []const u8, filename: []const u8, allocator: std.mem.Allocator) !Parser {
        return Parser{
            .tokens_ = std.ArrayList(token).init(allocator),
            .current = undefined,
            .allocator = allocator,
            .token_i = 0,
            .token_kinds = undefined,
            .source = source,
            .file_name = filename,
            .ast = ast.init(allocator),
        };
    }

    pub fn pushAll(self: *Parser) !void {
        var tok = tokenizer.init(self.source);
        var tokens = try tok.tokenize();
        for (tokens.items) |t| {
            try self.tokens_.append(t);
        }
    }

    fn parseType(self: *Parser) !types {
        switch (self.current.kind) {
            .int => {
                try self.consume(.int);
                return .int;
            },
            .string => {
                try self.consume(.string);
                return .string;
            },
            .bool => {
                try self.consume(.bool);
                return .bool;
            },
            .void => {
                try self.consume(.void);
                return .void;
            },
            .float => {
                try self.consume(.float);
                return .float;
            },
            else => {
                std.debug.print("|parseType| Unexpected token: {s}\n", .{self.current.lexeme});
                try self.PrintError();
            },
        }
        return .void;
    }

    // number | string | float | true | false
    fn parseValue(self: *Parser) !void {
        switch (self.current.kind) {
            .number_literal => {
                try self.consume(.number_literal);
            },
            .string_literal => {
                try self.consume(.string_literal);
            },
            .float_literal => {
                try self.consume(.float_literal);
            },
            .keyword_true, .keyword_false => {
                try self.consume(.keyword_true);
            },
            .identifier => {
                try self.consume(.identifier);
            },
            else => {
                std.debug.print("|parseValue| Unexpected token: {s}\n", .{self.current.lexeme});
                try self.PrintError();
                return Error.invalid_token;
            },
        }
    }

    // number | string | float | true | false
    fn parseValueType(self: *Parser) !vv.Types {
        switch (self.current.kind) {
            .number_literal => {
                return .int;
            },
            .string_literal => {
                return .string;
            },
            .float_literal => {
                return .float;
            },
            .keyword_true, .keyword_false => {
                return .bool;
            },
            .identifier => {
                return .void;
            },
            else => {
                std.debug.print("|parseValue| Unexpected token: {s}\n", .{self.current.lexeme});
                try self.PrintError();
                return Error.invalid_token;
            },
        }
    }

    // let var_name : type = value;
    fn parseVariableDecl(self: *Parser) !node {
        var expr: vv.Expression = undefined;
        if (self.current.kind == .keyword_let) {
            try self.consume(.keyword_let);
        }
        const var_name = self.current.lexeme;
        try self.consume(.identifier);
        try self.consume(.colon);
        var var_type = try self.parseType();
        var value: []const u8 = undefined;
        if (self.current.kind == .equal) {
            try self.consume(.equal);
            value = self.current.lexeme;
            expr = try self.parseExpression();
        }
        try self.expectSimicolon();
        const v = node{ .VariableDecl = .{
            .name = var_name,
            .Type = var_type,
            .value = expr,
        } };
        return v;
    }

    // ( arg1 : type |  arg2 : type | .... )
    fn parseFunctionArgments(self: *Parser) !std.ArrayList(vv.VariableDecl) {
        var args = std.ArrayList(vv.VariableDecl).init(self.allocator);
        var name = self.current.lexeme;
        try self.consume(.identifier);
        try self.consume(.colon);
        var v_type = try self.parseType();
        try args.append(.{ .name = name, .Type = v_type, .value = undefined });
        while (self.current.kind == .pipe) {
            try self.consume(.pipe);
            name = self.current.lexeme;
            try self.consume(.identifier);
            try self.consume(.colon);
            try args.append(.{ .name = name, .Type = try self.parseType(), .value = undefined });
        }
        return args;
    }

    fn isOperator(self: *Parser) bool {
        switch (self.current.kind) {
            .plus, .minus, .asterisk, .slash, .equal_equal, .plus_equal, .less_than, .less_than_equal, .greater_than, .greater_than_equal => {
                return true;
            },
            else => {
                return false;
            },
        }
        return false;
    }

    fn getOperator(self: *Parser) !vv.Operator {
        switch (self.current.kind) {
            .plus => {
                try self.consume(.plus);
                return .plus;
            },
            .minus => {
                try self.consume(.minus);
                return .minus;
            },
            .asterisk => {
                try self.consume(.asterisk);
                return .multiply;
            },
            .equal_equal => {
                try self.consume(.equal_equal);
                return .equal_equal;
            },
            .slash => {
                try self.consume(.slash);
                return .divide;
            },
            .plus_equal => {
                try self.consume(.plus_equal);
                return .plus_equal;
            },
            .less_than => {
                try self.consume(.less_than);
                return .less_than;
            },
            .less_than_equal => {
                try self.consume(.less_than_equal);
                return .less_than_equal;
            },
            .greater_than => {
                try self.consume(.greater_than);
                return .greater_than;
            },
            .greater_than_equal => {
                try self.consume(.greater_than_equal);
                return .greater_than_equal;
            },
            else => {
                std.debug.print("|getOperator| Unexpected token: {s}\n", .{self.current.lexeme});
            },
        }
        return undefined;
    }

    fn parseFunctionCall(self: *Parser, func_name: []const u8) !vv.Expression {
        var args = std.ArrayList(vv.Expression).init(self.allocator);
        var v: vv.Expression = undefined;
        if (self.current.kind == .left_paren) {
            try self.consume(.left_paren);
            while (self.current.kind != .right_paren) {
                if (self.current.kind == .comma) {
                    try self.consume(.comma);
                }
                var name = self.current.lexeme;
                if (self.current.kind == .number_literal) {
                    var v_left = vv.Expr{ .LiteralExpr = .{
                        .value = name,
                    } };
                    try self.consume(.number_literal);
                    while (self.isOperator()) {
                        var op = try self.getOperator();
                        if (self.current.kind == .number_literal) {
                            var v_right = vv.Expr{ .LiteralExpr = .{
                                .value = self.current.lexeme,
                            } };
                            try self.consume(.number_literal);
                            try args.append(.{ .BinaryExpr = .{
                                .left = v_left,
                                .operator = op,
                                .right = v_right,
                            } });
                        } else if (self.current.kind == .identifier) {
                            var v_right = vv.Expr{ .VariableReference = .{
                                .name = self.current.lexeme,
                            } };
                            try self.consume(.identifier);
                            if (self.current.kind == .left_paren) {
                                try args.append(try self.parseFunctionCall(name));
                            } else {
                                try args.append(.{ .BinaryExpr = .{
                                    .left = v_left,
                                    .operator = op,
                                    .right = v_right,
                                } });
                            }
                        }
                    }
                }
                if (self.current.kind == .identifier) {
                    var lhs = self.current.lexeme;
                    var rhs: []const u8 = "";
                    var rightVar: vv.Expr = undefined;
                    var leftVar: vv.Expr = undefined;
                    try self.consume(.identifier);
                    if (self.current.kind == .left_paren) {
                        leftVar = try self.parseFunctionCallExpr(lhs);
                    }
                    if (!self.isOperator()) {
                        try args.append(.{
                            .VariableReference = .{
                                .name = lhs,
                            },
                        });
                    } else {
                        var op = try self.getOperator();
                        if (self.current.kind == .number_literal) {
                            rhs = self.current.lexeme;
                            try self.consume(.number_literal);
                            rightVar = vv.Expr{ .LiteralExpr = .{
                                .value = rhs,
                            } };
                        } else if (self.current.kind == .identifier) {
                            rhs = self.current.lexeme;
                            try self.consume(.identifier);
                            if (self.current.kind == .left_paren) {
                                rightVar = try self.parseFunctionCallExpr(rhs);
                            }
                            rightVar = vv.Expr{ .VariableReference = .{
                                .name = rhs,
                            } };
                        }
                        try args.append(.{ .BinaryExpr = .{
                            .left = leftVar,
                            .operator = op,
                            .right = rightVar,
                        } });
                    }
                }
            }

            try self.consume(.right_paren);

            v = vv.Expression{ .FunctionCall = .{
                .name = func_name,
                .args = args,
            } };
        }
        return v;
    }

    fn parseFunctionCallExpr(self: *Parser, func_name: []const u8) !vv.FunctionCall {
        var args = std.ArrayList(vv.Expression).init(self.allocator);
        if (self.current.kind == .left_paren) {
            try self.consume(.left_paren);
            while (self.current.kind != .right_paren) {
                if (self.current.kind == .comma) {
                    try self.consume(.comma);
                }
                if (self.current.kind == .number_literal) {
                    var value = self.current.lexeme;
                    try self.consume(.number_literal);
                    var v_left = vv.Expr{ .LiteralExpr = .{
                        .value = value,
                    } };
                    if (!self.isOperator()) {
                        try args.append(.{ .LiteralExpr = .{
                            .value = value,
                        } });
                    } else {
                        var op = try self.getOperator();
                        var v_right = vv.Expr{ .LiteralExpr = .{
                            .value = self.current.lexeme,
                        } };
                        if (self.current.kind == .number_literal) {
                            try self.consume(.number_literal);
                            try args.append(.{ .BinaryExpr = .{
                                .left = v_left,
                                .operator = op,
                                .right = v_right,
                            } });
                        }
                        if (self.current.kind == .identifier) {
                            v_right = vv.Expr{ .VariableReference = .{
                                .name = self.current.lexeme,
                            } };
                            try self.consume(.identifier);
                            try args.append(.{ .BinaryExpr = .{
                                .left = v_left,
                                .operator = op,
                                .right = v_right,
                            } });
                        }
                    }
                }

                if (self.current.kind == .identifier) {
                    var lhs = self.current.lexeme;
                    try self.consume(.identifier);
                    var rhs: []const u8 = "";
                    var rightVar: vv.Expr = vv.Expr{ .VariableReference = .{
                        .name = rhs,
                    } };
                    var leftVar = vv.Expr{ .VariableReference = .{
                        .name = lhs,
                    } };
                    if (!self.isOperator()) {
                        try args.append(.{
                            .VariableReference = .{
                                .name = lhs,
                            },
                        });
                    } else {
                        var op = try self.getOperator();
                        if (self.current.kind == .number_literal) {
                            rhs = self.current.lexeme;
                            try self.consume(.number_literal);
                            rightVar = vv.Expr{ .LiteralExpr = .{
                                .value = rhs,
                            } };
                        } else if (self.current.kind == .identifier) {
                            rhs = self.current.lexeme;
                            try self.consume(.identifier);
                            if (self.current.kind == .left_paren) {
                                var func = try self.parseFunctionCallExpr(rhs);
                                rightVar = vv.Expr{ .FunctionCall = .{
                                    .name = func.name,
                                    .args = func.args,
                                } };
                            }

                            rightVar = vv.Expr{ .VariableReference = .{
                                .name = rhs,
                            } };
                        }
                        try args.append(.{ .BinaryExpr = .{
                            .left = leftVar,
                            .operator = op,
                            .right = rightVar,
                        } });
                    }
                }
            }
            try self.consume(.right_paren);
        }
        return vv.FunctionCall{
            .name = func_name,
            .args = args,
        };
    }

    fn parseExpression(self: *Parser) !vv.Expression {
        switch (self.current.kind) {
            .number_literal => {
                var value = self.current.lexeme;
                var left = vv.Expr{ .LiteralExpr = .{
                    .value = value,
                } };
                var v = vv.Expression{ .LiteralExpr = .{
                    .value = self.current.lexeme,
                } };
                try self.consume(.number_literal);
                while (self.isOperator()) {
                    var op = try self.getOperator();
                    var right = vv.Expr{ .LiteralExpr = .{
                        .value = value,
                    } };
                    try self.consume(.number_literal);
                    v = vv.Expression{ .BinaryExpr = .{
                        .left = left,
                        .operator = op,
                        .right = right,
                    } };
                }
                return v;
            },
            .string_literal => {
                var v = vv.Expression{ .LiteralExpr = .{
                    .value = self.current.lexeme,
                } };
                try self.consume(.string_literal);
                return v;
            },
            .float_literal => {
                var v = vv.Expression{ .LiteralExpr = .{
                    .value = self.current.lexeme,
                } };
                try self.consume(.float_literal);
                return v;
            },
            .identifier => {
                var v = vv.Expression{ .VariableReference = .{
                    .name = self.current.lexeme,
                } };
                var left = vv.Expr{ .VariableReference = .{
                    .name = self.current.lexeme,
                } };
                var func_name = self.current.lexeme;
                try self.consume(.identifier);
                // Function Call
                if (self.current.kind == .left_paren) {
                    var left_function = try self.parseFunctionCallExpr(func_name);
                    var left_function_expr = vv.Expr{ .FunctionCall = .{
                        .name = func_name,
                        .args = left_function.args,
                    } };
                    var right_function_expr: vv.Expr = undefined;
                    if (!self.isOperator()) {
                        return vv.Expression{ .FunctionCall = .{
                            .name = func_name,
                            .args = left_function.args,
                        } };
                    } else {
                        var op = try self.getOperator();
                        if (self.current.kind == .number_literal) {
                            var right_value = self.current.lexeme;
                            try self.consume(.number_literal);
                            var right = vv.Expr{ .LiteralExpr = .{
                                .value = right_value,
                            } };
                            return vv.Expression{ .BinaryExpr = .{
                                .left = left_function_expr,
                                .operator = op,
                                .right = right,
                            } };
                        } else if (self.current.kind == .identifier) {
                            var right_value_name = self.current.lexeme;
                            try self.consume(.identifier);
                            if (self.current.kind == .left_paren) {
                                var right_function = try self.parseFunctionCallExpr(func_name);

                                right_function_expr = vv.Expr{ .FunctionCall = .{
                                    .name = right_value_name,
                                    .args = right_function.args,
                                } };
                                return vv.Expression{ .BinaryExpr = .{
                                    .left = left_function_expr,
                                    .operator = op,
                                    .right = right_function_expr,
                                } };
                            } else {
                                var right = vv.Expr{ .VariableReference = .{
                                    .name = right_value_name,
                                } };
                                return vv.Expression{ .BinaryExpr = .{
                                    .left = left_function_expr,
                                    .operator = op,
                                    .right = right,
                                } };
                            }
                        }
                    }
                }

                while (self.isOperator()) {
                    var op = try self.getOperator();
                    var right: vv.Expr = undefined;
                    switch (self.current.kind) {
                        .number_literal => {
                            var value = self.current.lexeme;
                            try self.consume(.number_literal);
                            return vv.Expression{ .BinaryExpr = .{ .left = left, .operator = op, .right = vv.Expr{ .LiteralExpr = .{
                                .value = value,
                            } } } };
                        },
                        .float_literal => {
                            var value = self.current.lexeme;
                            try self.consume(.float_literal);
                            return vv.Expression{ .BinaryExpr = .{ .left = left, .operator = op, .right = vv.Expr{ .LiteralExpr = .{
                                .value = value,
                            } } } };
                        },
                        .identifier => {
                            var value = self.current.lexeme;
                            try self.consume(.identifier);

                            var func = try self.parseFunctionCallExpr(value);
                            var f_right = vv.Expr{ .FunctionCall = .{
                                .name = func.name,
                                .args = func.args,
                            } };
                            if (self.current.kind == .left_paren) {
                                return vv.Expression{ .BinaryExpr = .{
                                    .left = left,
                                    .operator = op,
                                    .right = f_right,
                                } };
                            } else {
                                right = vv.Expr{ .VariableReference = .{
                                    .name = value,
                                } };
                            }
                        },
                        else => {
                            std.debug.print("|parseExpression| Unexpected token: {s}\n", .{self.current.lexeme});
                        },
                    }
                    var v2 = vv.Expression{ .BinaryExpr = .{
                        .left = left,
                        .operator = op,
                        .right = right,
                    } };
                    return v2;
                }
                return v;
            },
            else => {
                std.debug.print("|parseExpression| Unexpected token: {s}\n", .{self.current.lexeme});
            },
        }
        return vv.Expression{
            .VariableReference = .{
                .name = self.current.lexeme,
            },
        };
    }

    fn parseReturn(self: *Parser) !node {
        try self.consume(.keyword_return);
        var expr2 = try self.parseExpression();
        try self.expectSimicolon();
        return node{ .ReturnStmt = .{
            .Value = expr2,
        } };
    }

    fn parseVariableReferance(self: *Parser) !node {
        var name = self.current.lexeme;
        try self.consume(.identifier);
        var op: vv.Operator = undefined;
        switch (self.current.kind) {
            .plus_equal => {
                op = .plus_equal;
                try self.consume(.plus_equal);
            },
            .equal => {
                op = .equal;
                try self.consume(.equal);
            },
            .equal_equal => {
                op = .equal_equal;
                try self.consume(.equal_equal);
            },
            .minus_equal => {
                op = .minus_equal;
                try self.consume(.minus_equal);
            },
            else => {
                @panic("ParseVariableReferance: this operator is not supported");
            },
        }
        var v_type = try self.parseValueType();
        var value = try self.parseExpression();
        try self.expectSimicolon();
        return node{
            .VariableReference = .{
                .value = value,
                .name = name,
                .Operator = op,
                .value_type = v_type,
            },
        };
    }

    fn parseIf(self: *Parser) !node {
        try self.consume(.keyword_if);
        try self.consume(.left_paren);
        var cond = try self.parseExpression();
        try self.consume(.right_paren);
        try self.consume(.left_brace);
        var body_nodes = std.ArrayList(node).init(self.allocator);
        var b = vv.Body{
            .body = body_nodes,
        };
        while (self.current.kind != .right_brace) {
            switch (self.current.kind) {
                .keyword_let => {
                    var stmt = try self.parseVariableDecl();
                    try b.body.append(stmt);
                },
                .keyword_return => {
                    var stmt = try self.parseReturn();
                    try b.body.append(stmt);
                },
                .keyword_if => {
                    var stmt = try self.parseIf();
                    try b.body.append(stmt);
                },
                .identifier => {
                    var stmt = try self.parseVariableReferance();
                    try b.body.append(stmt);
                },
                else => {
                    std.debug.print("|parseStatement| Unexpected token: {s}\n", .{self.current.lexeme});
                    try self.PrintError();
                    return Error.invalid_token;
                },
            }
        }
        try self.consume(.right_brace);
        var else_body: ?vv.Body = vv.Body{
            .body = std.ArrayList(node).init(self.allocator),
        };
        if (self.current.kind == .keyword_else) {
            try self.consume(.keyword_else);
            try self.consume(.left_brace);
            while (self.current.kind != .right_brace) {
                switch (self.current.kind) {
                    .keyword_let => {
                        var stmt = try self.parseVariableDecl();
                        try else_body.?.body.append(stmt);
                    },
                    .keyword_return => {
                        var stmt = try self.parseReturn();
                        try else_body.?.body.append(stmt);
                    },
                    .keyword_if => {
                        var stmt = try self.parseIf();
                        try else_body.?.body.append(stmt);
                    },
                    .identifier => {
                        var stmt = try self.parseVariableReferance();
                        try else_body.?.body.append(stmt);
                    },
                    else => {
                        std.debug.print("|parseStatement| Unexpected token: {s}\n", .{self.current.lexeme});
                        try self.PrintError();
                        return Error.invalid_token;
                    },
                }
            }
            try self.consume(.right_brace);
        }
        return node{ .IfStmt = .{
            .condition = cond,
            .body = b,
            .else_body = else_body orelse return Error.invalid_token,
        } };
    }

    fn parseStatement(self: *Parser) !node {
        switch (self.current.kind) {
            .keyword_let => {
                return try self.parseVariableDecl();
            },
            .keyword_return => {
                return try self.parseReturn();
            },
            .keyword_if => {
                return try self.parseIf();
            },
            .identifier => {
                return try self.parseVariableReferance();
            },
            else => {
                std.debug.print("|parseStatement| Unexpected token: {s}\n", .{self.current.lexeme});
                try self.PrintError();
                return Error.invalid_token;
            },
        }
    }

    fn parseFunctionBody(self: *Parser) !vv.Body {
        try self.consume(.left_brace);
        var body_nodes = std.ArrayList(node).init(self.allocator);
        var b = vv.Body{
            .body = body_nodes,
        };
        while (self.current.kind != .right_brace) {
            var stsmt = try self.parseStatement();
            try b.body.append(stsmt);
        }
        try self.consume(.right_brace);
        return b;
    }

    // fn func_name ( arg1 : type |  arg2 : type ) : type { }
    fn parseFunctionDecl(self: *Parser) !node {
        if (self.current.kind == .keyword_fn) {
            try self.consume(.keyword_fn);
        }
        const func_name = self.current.lexeme;
        var args = std.ArrayList(vv.VariableDecl).init(self.allocator);
        try self.consume(.identifier);
        try self.consume(.left_paren);
        while (self.current.kind != .right_paren) {
            args = try self.parseFunctionArgments();
        }
        try self.consume(.right_paren);
        try self.consume(.colon);
        var func_type = try self.parseType();
        var func_body = try self.parseFunctionBody();
        var f: node = node{ .FunctionDecl = .{
            .name = func_name,
            .args = args,
            .body = func_body,
            .return_type = func_type,
        } };
        return f;
    }

    pub fn parse(self: *Parser) !void {
        while (self.current.kind != .eof) : (self.current = self.tokens_.items[self.token_i]) {
            switch (self.current.kind) {
                .keyword_let => {
                    var vara = try self.parseVariableDecl();
                    try self.ast.push(vara);
                },
                .keyword_fn => {
                    var func = try self.parseFunctionDecl();
                    try self.ast.push(func);
                },
                else => {
                    if (self.current.kind == .identifier) {
                        try self.PrintError();
                        std.io.getStdOut().writeAll("You can't call a function with an identifier\n") catch {};
                        break;
                    }
                },
            }
        }
    }

    fn expectSimicolon(self: *Parser) !void {
        if (self.current.kind == .semicolon) {
            try self.next();
        }
    }

    pub fn deinit(self: *Parser) void {
        self.tokens_.deinit();
    }

    pub fn getNextToken(self: *Parser) token {
        return self.tokens_.items[self.token_i + 1];
    }

    pub fn next(self: *Parser) !void {
        if (self.token_i >= self.tokens_.items.len - 1) {
            return;
        }

        self.token_i += 1;
        self.current = self.tokens_.items[self.token_i];
    }

    fn getLineToString(self: *Parser, line_number: usize) ![]const u8 {
        var line_count: usize = 1;
        var file = try std.fs.cwd().openFile(self.file_name, .{});
        var buffer = [_]u8{0};
        var current_line = std.ArrayList(u8).init(self.allocator);
        var reached_target_line = false;

        while (line_count <= line_number) {
            const read_result = try file.read(buffer[0..]);
            if (read_result == 0) {
                return undefined;
            }

            if (buffer[0] == '\n') {
                line_count += 1;
                if (line_count == line_number) {
                    reached_target_line = true;
                }
            } else if (reached_target_line) {
                try current_line.append(buffer[0]);
            }
        }

        if (reached_target_line) {
            return current_line.items;
        } else {
            return undefined;
        }
    }

    pub fn PrintError(self: *Parser) !void {
        const current_token = self.tokens_.items[self.token_i - 1];
        const line = current_token.location.line;
        const col = current_token.location.column + 2;
        var line_string = try self.getLineToString(line);
        std.debug.print("{s}\n", .{line_string});
        for (0..col) |_| {
            std.debug.print("~", .{});
        }
        std.debug.print("^\n", .{});
        std.debug.print("{s}:{}:{}: ", .{
            self.file_name,
            line,
            col,
        });
    }

    pub fn expect(self: *Parser, kind: token.Kind) !bool {
        if (self.current.kind == kind) {
            return true;
        }
        return false;
    }

    fn consume(self: *Parser, kind: token.Kind) !void {
        if (self.current.kind == kind) {
            try self.next();
        } else {
            const expected_kind_name = @tagName(kind);
            const found_kind_name = self.current.lexeme;

            std.debug.print("{s}:{}:{}: expected {s}, found \"{s}\"\n", .{
                self.file_name,
                self.current.location.line,
                self.current.location.column,
                expected_kind_name,
                found_kind_name,
            });
            try self.PrintError();
            return Error.invalid_token;
        }
    }
};

fn testParser(source: []const u8, expected_nodes: []const vv.Node) !void {
    var allocator = std.testing.allocator;
    var par = Parser{
        .tokens_ = std.ArrayList(token).init(allocator),
        .current = undefined,
        .allocator = allocator,
        .token_i = 0,
        .token_kinds = undefined,
        .source = source,
        .file_name = "test.x",
        .ast = ast.init(allocator),
    };
    defer par.deinit();
    defer par.ast.deinit();
    try par.pushAll();
    try par.parse();

    if (expected_nodes.len != par.ast.nodes.items.len) {
        std.debug.print("Expected {d} nodes but found {d}\n", .{ expected_nodes.len, par.ast.nodes.items.len });
        return error.test_failed;
    }

    for (par.ast.nodes.items, 0..) |expected, i| {
        if (i >= expected_nodes.len) {
            std.debug.print("Unexpected node at index {d}\n", .{i});
            return;
        }
        try std.testing.expectEqualDeep(expected, par.ast.nodes.items[i]);
    }
}

test "parse function" {
    var source = "fn main(): int {}";
    try testParser(source, &[_]vv.Node{.{ .FunctionDecl = .{
        .name = "main",
        .args = std.ArrayList(vv.VariableDecl).init(std.testing.allocator),
        .body = vv.Body{
            .body = std.ArrayList(vv.Node).init(std.testing.allocator),
        },
        .return_type = .int,
    } }});
}

test "parse variable" {
    var source = "let a: int = 10;";
    try testParser(source, &[_]vv.Node{.{ .VariableDecl = .{
        .name = "a",
        .Type = .int,
        .value = vv.Expression{ .LiteralExpr = .{
            .value = "10",
        } },
    } }});
}
