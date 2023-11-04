<<<<<<< HEAD
const std = @import("std");
const tokenizer = @import("tokenizer.zig").Tokenizer;
const token = @import("tokenizer.zig").Token;
const assert = std.debug.assert;
const File = std.fs.File;
const SymbolTable = @import("symbol_table.zig").symbol_table;
=======
const Self = @This();
const ast = @import("ast.zig").ast;
const node = @import("ast.zig").Node;
const std = @import("std");
const tokenizer = @import("lexer.zig").Tokenizer;
const token = @import("lexer.zig").Token;
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
>>>>>>> 8651675 (some fixes)

pub const Parser = struct {
    tokens_: std.ArrayList(token),
    current: token,
    allocator: std.mem.Allocator,
    token_i: usize,
    token_kinds: []const token.Kind,
    source: []const u8,
    file_name: []const u8,
<<<<<<< HEAD
    symbol_table: SymbolTable,
=======
    ast: ast,
>>>>>>> 8651675 (some fixes)

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
<<<<<<< HEAD
            .symbol_table = try SymbolTable.init(allocator),
=======
            .ast = ast.init(allocator),
>>>>>>> 8651675 (some fixes)
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

    pub fn parse(self: *Parser) !void {
        try self.next();
        for (self.tokens_.items) |t| {
            switch (t.kind) {
                .eof => {
                    break;
                },
                .keyword_let => {
<<<<<<< HEAD
=======
                    if (self.current.kind == .keyword_let) {
                        const var_name = self.current.lexeme;
                        _ = var_name;
                        try self.consume(.keyword_let);
                    }
>>>>>>> 8651675 (some fixes)
                    const var_name = self.current.lexeme;
                    try self.consume(.identifier);
                    try self.consume(.colon);
                    try self.consume(.int);
                    try self.consume(.equal);
                    var value = self.current.lexeme;
                    try self.consume(.number_literal);
                    try self.consume(.semicolon);
<<<<<<< HEAD
                    try self.symbol_table.addVariable(var_name, value);
=======
                    const v: node = node{ .VariableDecl = .{
                        .name = var_name,
                        .Type = .string,
                        .value = value,
                    } };
                    try self.ast.push(v);
>>>>>>> 8651675 (some fixes)
                },
                .identifier => {
                    std.debug.print("Current kind: {s}\n", .{@tagName(self.current.kind)});
                },
                else => {},
            }
        }
        std.debug.print("parsed {d} tokens\n", .{self.token_i});
<<<<<<< HEAD
        self.symbol_table.print();
=======
>>>>>>> 8651675 (some fixes)
    }

    pub fn deinit(self: *Parser) void {
        self.tokens_.deinit();
    }

    pub fn getNextToken(self: *Parser) token {
        return self.tokens_.items[self.token_i + 1];
    }

    pub fn next(self: *Parser) !void {
<<<<<<< HEAD
=======
        if (self.token_i >= self.tokens_.items.len) {
            return;
        }
>>>>>>> 8651675 (some fixes)
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
        const line = self.current.location.line;
        const col = self.current.location.column;
        var line_string = try self.getLineToString(line);

        std.debug.print("{s}\n", .{line_string});
        for (0..col) |i| {
            _ = i;
            std.debug.print("~", .{});
        }
        std.debug.print("^\n", .{});
    }

    pub fn consume(self: *Parser, kind: token.Kind) !void {
        if (self.current.kind == kind) {
            self.current = self.tokens_.items[self.token_i];
            self.current.location.line = self.tokens_.items[self.token_i].location.line;
            self.current.location.column = self.tokens_.items[self.token_i].location.column;
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
        }
    }
};
