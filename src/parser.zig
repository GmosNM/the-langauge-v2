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

// Roadmap
// - Parse

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
        for (self.tokens_.items) |t| {
            std.debug.print("{s} \"{s}\" Location: Col: {} Line: {}\n", .{ @tagName(t.kind), t.lexeme, t.location.column, t.location.line });
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
            .plus, .minus, .asterisk, .slash => {
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
            .slash => {
                try self.consume(.slash);
                return .divide;
            },
            else => {
                std.debug.print("|getOperator| Unexpected token: {s}\n", .{self.current.lexeme});
            },
        }
        return .plus;
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
                if (self.isOperator()) {
                    var op = try self.getOperator();
                    var right = vv.Expr{ .LiteralExpr = .{
                        .value = value,
                    } };
                    try self.consume(.number_literal);
                    var v2 = vv.Expression{ .BinaryExpr = .{
                        .left = left,
                        .operator = op,
                        .right = right,
                    } };
                    return v2;
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
                try self.consume(.identifier);
                if (self.isOperator()) {
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
                            return vv.Expression{ .BinaryExpr = .{ .left = left, .operator = op, .right = vv.Expr{ .VariableReference = .{
                                .name = value,
                            } } } };
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
        try self.consume(.equal);
        var v_type = try self.parseValueType();
        var value = try self.parseExpression();
        try self.expectSimicolon();
        return node{
            .VariableReference = .{
                .value = value,
                .name = name,
                .value_type = v_type,
            },
        };
    }

    fn parseStatement(self: *Parser) !node {
        switch (self.current.kind) {
            .keyword_let => {
                return try self.parseVariableDecl();
            },
            .keyword_return => {
                return try self.parseReturn();
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
        var b = func_body;
        var f: node = node{ .FunctionDecl = .{
            .name = func_name,
            .args = args,
            .body = b,
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
        std.debug.print("parsed {d} tokens\n", .{self.token_i});
    }

    fn expectSimicolon(self: *Parser) !void {
        if (self.current.kind == .semicolon) {
            try self.next();
        } else {
            try self.PrintError();
            std.debug.print("Syntax error: Expected semicolon\n", .{});
            return Error.expected_simicolon;
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
