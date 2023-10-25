const std = @import("std");
const tokenizer = @import("tokenizer.zig").Tokenizer;
const token = @import("tokenizer.zig").Token;
const assert = std.debug.assert;
const ast = @import("ast.zig");
const File = std.fs.File;

pub const Parser = struct {
    tokens_: std.ArrayList(token),
    current: token,
    allocator: std.mem.Allocator,
    token_i: usize,
    token_kinds: []const token.Kind,
    node_list: std.ArrayList(ast.Node),
    source: []const u8,
    file_name: []const u8,

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
            .node_list = std.ArrayList(ast.Node).init(allocator),
            .source = source,
            .file_name = filename,
        };
    }

    pub fn pushAll(self: *Parser) !void {
        var tok = tokenizer.init(self.source);
        var tokens = try tok.tokenize();
        for (tokens.items) |t| {
            try self.tokens_.append(t);
        }
    }

    pub fn parseType(self: *Parser) !void {
        switch (self.current.kind) {
            .int => {
                try self.consume(.int);
            },
            .float => {
                try self.consume(.float);
            },
            .char => {
                try self.consume(.char);
            },
            .string => {
                try self.consume(.string);
            },
            .void => {
                try self.consume(.void);
            },
            .bool => {
                try self.consume(.bool);
            },
            else => {
                std.debug.print("expected type\n", .{});
            },
        }
    }

    pub fn parse(self: *Parser) !void {
        for (self.tokens_.items) |t| {
            switch (t.kind) {
                .keyword_let => {
                    try self.consume(.keyword_let);
                    try self.consume(.identifier);
                    try self.consume(.colon);
                    try self.parseType();
                    try self.consume(.equal);
                    try self.consume(.int);
                },
                else => {},
            }
        }
        std.debug.print("parsed {d} tokens\n", .{self.token_i});
        try self.printAst();
    }

    pub fn printAst(self: *Parser) !void {
        for (self.node_list.items) |node| {
            std.debug.print("{}", .{node});
        }
    }

    pub fn nextToken(p: *Parser) !token {
        if (p.token_i < p.tokens_.items.len) {
            return p.current;
        } else {
            std.debug.print("out of tokens\n", .{});
            p.current = token{ .kind = .invalid, .lexeme = "", .location = .{ .start = 0, .end = 0, .line = 0, .column = 0 } };
            return error.out_of_tokens;
        }
    }

    pub fn next(self: *Parser) !void {
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

        std.debug.print("\t{s}\t", .{line_string});
        for (0..col) |i| {
            _ = i;
            std.debug.print("~", .{});
        }
        std.debug.print("^\n", .{});
    }

    pub fn consume(self: *Parser, kind: token.Kind) !void {
        self.current = self.tokens_.items[self.token_i];
        if (self.current.kind == kind) {
            self.current = self.tokens_.items[self.token_i];
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
