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

    // let var_name : type = value;
    fn parseVariableDecl(self: *Parser) !node {
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
            try self.parseValue();
        }
        try self.expectSimicolon();
        const v = node{ .VariableDecl = .{
            .name = var_name,
            .Type = var_type,
            .value = value,
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

    fn parseReturn(self: *Parser) !node {
        try self.consume(.keyword_return);
        var value = self.current.lexeme;
        _ = try self.parseValue();
        var expr = vv.Expression{ .LiteralExpr = .{
            .value = value,
        } };
        try self.expectSimicolon();
        return node{ .ReturnStmt = .{
            .Value = expr,
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
                else => {},
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
        var line_count: usize = 0;
        const buffer_size: usize = 4096;
        var buffer = [_]u8{0} ** buffer_size;
        var file = std.fs.cwd().openFile(self.file_name, .{}) catch {
            return error.file_not_found;
        };
        while (true) {
            const read_result = try file.read(&buffer);
            if (read_result == 0) {
                break;
            }

            for (buffer) |byte| {
                if (byte == '\n') {
                    line_count += 1;
                    if (line_count == line_number) {
                        const line = buffer[0..];
                        return line;
                    }
                }
            }
        }

        return "Line not found";
    }

    pub fn PrintError(self: *Parser) !void {
        const current_token = self.tokens_.items[self.token_i];
        const line = current_token.location.line;
        const col = current_token.location.column;
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
