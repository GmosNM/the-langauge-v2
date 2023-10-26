const std = @import("std");

pub const Token = struct {
    kind: Kind,
    lexeme: []const u8,
    location: Location,

    pub const Location = struct {
        line: usize,
        column: usize,
        start: usize,
        end: usize,
    };
    pub const Kind = enum {
        invalid,
        eof,
        identifier,
        string_literal,
        number_literal,
        float_literal,
        char_literal,
        // types
        int,
        float,
        char,
        string,
        bool,
        void,
        //keywords
        keyword_fn,
        keyword_if,
        keyword_else,
        keyword_while,
        keyword_for,
        keyword_let,
        keyword_true,
        keyword_false,
        keyword_return,
        keyword_break,
        keyword_continue,
        keyword_match,
        keyword_const,
        keyword_and,
        keyword_or,
        keyword_enum,
        keyword_struct,
        keyword_test,
        keyword_extern,
        keyword_export,
        keyword_inline,
        // operators
        asterisk,
        asterisk_equal,
        asterisk_asterisk,
        slash,
        percent,
        plus,
        plus_equal,
        plus_plus,
        minus,
        minus_equal,
        less_than,
        greater_than,
        less_than_equal,
        greater_than_equal,
        equal_equal,
        bang_equal,
        equal,
        bang,
        question_mark,
        pipe,
        pipe_pipe,
        equal_right_arrow,
        push_left,
        push_right,
        // delimiters
        comma,
        semicolon,
        colon,
        dot,
        dot_dot,
        dot_dot_dot,
        arrow,
        ampersand,
        // punctuators
        left_paren,
        right_paren,
        left_brace,
        right_brace,
        left_bracket,
        right_bracket,
    };

    pub const keywords = std.ComptimeStringMap(Kind, .{
        .{ "fn", .keyword_fn },
        .{ "if", .keyword_if },
        .{ "else", .keyword_else },
        .{ "while", .keyword_while },
        .{ "for", .keyword_for },
        .{ "let", .keyword_let },
        .{ "true", .keyword_true },
        .{ "false", .keyword_false },
        .{ "return", .keyword_return },
        .{ "break", .keyword_break },
        .{ "continue", .keyword_continue },
        .{ "match", .keyword_match },
        .{ "const", .keyword_const },
        .{ "and", .keyword_and },
        .{ "or", .keyword_or },
        .{ "float", .float },
        .{ "int", .int },
        .{ "char", .char },
        .{ "string", .string },
        .{ "void", .void },
    });

    pub fn getKeyword(lexeme: []const u8) ?Kind {
        return keywords.get(lexeme);
    }
};

pub const Tokenizer = struct {
    source: []const u8,
    index: usize,
    current_token: ?Token,
    Allocation: std.heap.ArenaAllocator,
    tokens_count: usize = 0,

    pub fn dump(self: *Tokenizer, token: *const Token) void {
        _ = self;
        std.debug.print("{s} \"{s}\" Location: Col: {} Line: {}\n", .{ @tagName(token.kind), token.lexeme, token.location.column, token.location.line });
    }

    pub fn init(source: []const u8) Tokenizer {
        return Tokenizer{
            .source = source,
            .index = 0,
            .current_token = null,
            .Allocation = std.heap.ArenaAllocator.init(std.heap.page_allocator),
        };
    }

    fn isWhitespace(self: *Tokenizer, char: u8) bool {
        _ = self;
        return char == ' ' or char == '\t' or char == '\r' or char == '\n';
    }

    fn isDigit(self: *Tokenizer, char: u8) bool {
        _ = self;
        return char >= '0' and char <= '9';
    }

    fn isAlpha(self: *Tokenizer, char: u8) bool {
        _ = self;
        return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z');
    }

    fn isPunctuator(self: *Tokenizer, char: u8) bool {
        _ = self;
        return char == ':' or char == '(' or char == ')' or char == '{' or char == '}' or char == ';';
    }

    pub fn tokenize(self: *Tokenizer) !std.ArrayList(Token) {
        var tokens = std.ArrayList(Token).init(self.Allocation.allocator());
        var index: usize = 0;
        var col: usize = 1;
        var line: usize = 1;

        while (index < self.source.len) {
            var result: Token = Token{
                .kind = .eof,
                .lexeme = "",
                .location = .{ .start = index, .end = index, .line = line, .column = col },
            };

            switch (self.source[index]) {
                ' ', '\r' => {
                    col += 1;
                    index += 1;
                },
                '\t' => {
                    col += 4;
                    index += 1;
                },
                '\n' => {
                    line += 1;
                    col = 1;
                    index += 1;
                },
                ':' => {
                    result.kind = .colon;
                    result.lexeme = ":";
                    index += 1;
                },
                '(' => {
                    result.kind = .left_paren;
                    result.lexeme = "(";
                    index += 1;
                },
                ')' => {
                    result.kind = .right_paren;
                    result.lexeme = ")";
                    index += 1;
                },
                '{' => {
                    result.kind = .left_brace;
                    result.lexeme = "{";
                    index += 1;
                },
                '}' => {
                    result.kind = .right_brace;
                    result.lexeme = "}";
                    index += 1;
                },
                '[' => {
                    result.kind = .left_bracket;
                    result.lexeme = "[";
                    index += 1;
                },
                ']' => {
                    result.kind = .right_bracket;
                    result.lexeme = "]";
                    index += 1;
                },
                ';' => {
                    result.kind = .semicolon;
                    result.lexeme = ";";
                    index += 1;
                },
                ',' => {
                    result.kind = .comma;
                    result.lexeme = ",";
                    index += 1;
                },
                '.' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '.' and
                        index + 2 < self.source.len and self.source[index + 2] == '.')
                    {
                        result.lexeme = "...";
                        result.kind = .dot_dot_dot;
                        index += 3;
                    } else if (index + 1 < self.source.len and self.source[index + 1] == '.') {
                        result.lexeme = "..";
                        result.kind = .dot_dot;
                        index += 2;
                    } else {
                        result.kind = .dot;
                        result.lexeme = ".";
                        index += 1;
                    }
                },

                '+' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "+=";
                        result.kind = .plus_equal;
                        index += 2;
                    } else if (index + 1 < self.source.len and self.source[index + 1] == '+') {
                        result.lexeme = "++";
                        result.kind = .plus_plus;
                        index += 3;
                    } else {
                        result.kind = .plus;
                        result.lexeme = "+";
                        index += 1;
                    }
                },
                '-' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "-=";
                        result.kind = .minus_equal;
                        index += 2;
                    } else {
                        result.kind = .minus;
                        result.lexeme = "-";
                        index += 1;
                    }
                },

                '*' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "*=";
                        result.kind = .asterisk_equal;
                        index += 2;
                    } else if (index + 1 < self.source.len and self.source[index + 1] == '*') {
                        result.lexeme = "**";
                        result.kind = .asterisk_asterisk;
                        index += 3;
                    } else {
                        result.kind = .asterisk;
                        result.lexeme = "*";
                        index += 1;
                    }
                },
                '/' => {
                    result.kind = .slash;
                    result.lexeme = "/";
                    index += 1;
                },
                '%' => {
                    result.kind = .percent;
                    result.lexeme = "%";
                    index += 1;
                },
                '<' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "<=";
                        result.kind = .less_than_equal;
                        index += 2;
                    } else if (index + 1 < self.source.len and self.source[index + 1] == '<') {
                        result.lexeme = "<<";
                        result.kind = .push_left;
                        index += 3;
                    } else {
                        result.kind = .less_than;
                        result.lexeme = "<";
                        index += 1;
                    }
                },
                '>' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = ">=";
                        result.kind = .greater_than_equal;
                        index += 2;
                    } else {
                        result.kind = .greater_than;
                        result.lexeme = ">";
                        index += 1;
                    }
                },
                '=' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "==";
                        result.kind = .equal_equal;
                        index += 2;
                    } else {
                        result.kind = .equal;
                        result.lexeme = "=";
                        index += 1;
                    }
                },
                '!' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "!=";
                        result.kind = .bang_equal;
                        index += 2;
                    } else {
                        result.kind = .bang;
                        result.lexeme = "!";
                        index += 1;
                    }
                },
                '|' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '|') {
                        result.lexeme = "||";
                        result.kind = .pipe_pipe;
                        index += 2;
                    } else {
                        result.kind = .pipe;
                        result.lexeme = "|";
                        index += 1;
                    }
                },
                '?' => {
                    result.kind = .question_mark;
                    result.lexeme = "?";
                    index += 1;
                },
                '#' => {
                    while (index < self.source.len and self.source[index] != '\n') : (index += 1) {}
                },
                '0'...'9' => {
                    var isFloat = false;
                    var isExponent = false;
                    var start = index;

                    while (index < self.source.len and (((self.source[index] >= '0' and self.source[index] <= '9') or
                        (self.source[index] == '.' and !isFloat) and self.source[index + 1] != '.') or
                        (self.source[index] == 'x' and (index - start) == 1) or
                        (self.source[index] == '+' or self.source[index] == '-') or
                        ((self.source[index] == 'e' or self.source[index] == 'E')) or (std.ascii.isHex(self.source[index]) and (index - start) > 1 and !isFloat))) : (index += 1)
                        if (self.source[index] == '.') {
                            isFloat = true;
                            index += 1;
                        } else if ((self.source[index] == 'e' or self.source[index] == 'E') and isExponent) {
                            isExponent = true;
                            index += 1;
                        };

                    if (isFloat or isExponent) {
                        result.lexeme = self.source[start..index];
                        result.kind = .float_literal;
                    } else {
                        var lexeme = self.source[start..index];
                        if (Token.getKeyword(lexeme)) |kind| {
                            result.kind = kind;
                        } else {
                            result.lexeme = lexeme;
                            result.kind = .number_literal;
                        }
                    }
                },

                '\'' => {
                    var start = index;
                    index += 1;
                    while (index < self.source.len and self.source[index] != '\'') : (index += 1) {}
                    if (index < self.source.len) {
                        result.lexeme = self.source[(start + 1)..index];
                        result.kind = .char_literal;
                        index += 1;
                    }
                },
                'a'...'z', 'A'...'Z' => {
                    while (index < self.source.len and std.ascii.isAlphabetic(self.source[index]) and !self.isPunctuator(self.source[index])) : (index += 1) {}
                    const lexeme = self.source[result.location.start..index];
                    result.lexeme = lexeme;
                    result.kind = Token.getKeyword(lexeme) orelse .identifier;
                },

                '"' => {
                    var start = index + 1;
                    var escaped = false;
                    index += 1;
                    while (index < self.source.len) {
                        if (escaped) {
                            escaped = false;
                            switch (self.source[index]) {
                                'n' => index += 1,
                                't' => index += 1,
                                'r' => index += 1,
                                '\\' => index += 1,
                                '"' => index += 1,
                                'u' => index += 1,
                                'x' => index += 1,
                                else => {},
                            }
                        } else {
                            if (self.source[index] == '\\') {
                                escaped = true;
                            } else if (self.source[index] == '"') {
                                index += 1;
                                break;
                            }
                        }
                        index += 1;
                    }
                    result.lexeme = self.source[start .. index - 1];
                    result.kind = .string_literal;
                },

                else => {
                    index += 1;
                    result.location.column += 1;
                },
            }
            if (result.kind != .eof) {
                try tokens.append(result);
                self.current_token = tokens.items[tokens.items.len - 1];
                self.tokens_count += 1;
            }
        }
        try tokens.append(Token{ .kind = .eof, .lexeme = "EOF", .location = .{
            .end = self.source.len,
            .start = self.source.len,
            .column = col,
            .line = line,
        } });
        self.tokens_count += 1;
        col = index;
        return tokens;
    }
};

fn testTokenize(source: []const u8, expected_token_tags: []const Token.Kind) !void {
    var tokenizer = Tokenizer.init(source);
    var tokens = try tokenizer.tokenize();

    const num_tokens = expected_token_tags.len + 1;
    const num_actual_tokens = tokenizer.tokens_count;
    try std.testing.expectEqual(num_tokens, num_actual_tokens);

    for (expected_token_tags, 0..) |expected_token_tag, i| {
        try std.testing.expectEqual(expected_token_tag, tokens.items[i].kind);
    }

    try std.testing.expectEqual(Token.Kind.eof, tokens.items[num_tokens - 1].kind);
}

test "char" {
    try testTokenize("let x: char = 'a';", &.{ .keyword_let, .identifier, .colon, .char, .equal, .char_literal, .semicolon });
}

test "string" {
    try testTokenize("let x: string = \"foo\";", &.{ .keyword_let, .identifier, .colon, .string, .equal, .string_literal, .semicolon });
}

test "operators" {
    try testTokenize("+=", &.{.plus_equal});
    try testTokenize("+", &.{.plus});
    try testTokenize("++", &.{.plus_plus});

    try testTokenize("-=", &.{.minus_equal});
    try testTokenize("-", &.{.minus});

    try testTokenize("*=", &.{.asterisk_equal});
    try testTokenize("*", &.{.asterisk});
    try testTokenize("**", &.{.asterisk_asterisk});

    try testTokenize("/", &.{.slash});

    try testTokenize("%", &.{.percent});

    try testTokenize("<", &.{.less_than});
    try testTokenize("<=", &.{.less_than_equal});
    try testTokenize("<<", &.{.push_left});

    try testTokenize(">", &.{.greater_than});
    try testTokenize(">=", &.{.greater_than_equal});

    try testTokenize("==", &.{.equal_equal});
    try testTokenize("=", &.{.equal});
    try testTokenize("!=", &.{.bang_equal});

    try testTokenize(".", &.{.dot});
    try testTokenize("..", &.{.dot_dot});
    try testTokenize("...", &.{.dot_dot_dot});

    try testTokenize("|", &.{.pipe});
    try testTokenize("||", &.{.pipe_pipe});
}

test "number literals hexadecimal" {
    try testTokenize("0x0", &.{.number_literal});
    try testTokenize("0x1", &.{.number_literal});
    try testTokenize("0x2", &.{.number_literal});
    try testTokenize("0x3", &.{.number_literal});
    try testTokenize("0x4", &.{.number_literal});
    try testTokenize("0x5", &.{.number_literal});
    try testTokenize("0x6", &.{.number_literal});
    try testTokenize("0x7", &.{.number_literal});
    try testTokenize("0x8", &.{.number_literal});
    try testTokenize("0x9", &.{.number_literal});
    try testTokenize("0xa", &.{.number_literal});
    try testTokenize("0xb", &.{.number_literal});
    try testTokenize("0xc", &.{.number_literal});
    try testTokenize("0xd", &.{.number_literal});
    try testTokenize("0xe", &.{.number_literal});
    try testTokenize("0xf", &.{.number_literal});
    try testTokenize("0xA", &.{.number_literal});
    try testTokenize("0xB", &.{.number_literal});
    try testTokenize("0xC", &.{.number_literal});
    try testTokenize("0xD", &.{.number_literal});
    try testTokenize("0xE", &.{.number_literal});
    try testTokenize("0xF", &.{.number_literal});
    try testTokenize("0x10", &.{.number_literal});
    try testTokenize("0x1F", &.{.number_literal});
    try testTokenize("0xFF", &.{.number_literal});
    try testTokenize("0xFFF", &.{.number_literal});
}

test "string literals" {
    try testTokenize("\"Hello, World!\"", &.{.string_literal});
    try testTokenize("\"Newline: \\n\\nTab: \\t\\tBackslash: \\\\\"", &.{.string_literal});
    try testTokenize("\"Unicode: \\u03B1\\u03B2\"", &.{.string_literal});
    try testTokenize("\"Escaped escape: \\\\\\\\\"", &.{.string_literal});
}

test "scientific notation" {
    try testTokenize("3.0e5", &.{.float_literal});
    try testTokenize("2.5e-3", &.{.float_literal});
    try testTokenize("6.022e23", &.{.float_literal});

    try testTokenize("1e3", &.{.number_literal});
    try testTokenize("4E-2", &.{.number_literal});
    try testTokenize("0.123e+4", &.{.float_literal});
    try testTokenize("7.77e7", &.{.float_literal});
    try testTokenize("9.999E-6", &.{.float_literal});
}

test "complex expressions" {
    try testTokenize("3 * (4 + 2) / (1 - 5)", &.{ .number_literal, .asterisk, .left_paren, .number_literal, .plus, .number_literal, .right_paren, .slash, .left_paren, .number_literal, .minus, .number_literal, .right_paren });
}

test "reserved keywords" {
    try testTokenize("const if else while for return", &.{ .keyword_const, .keyword_if, .keyword_else, .keyword_while, .keyword_for, .keyword_return });
}
