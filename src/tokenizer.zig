const std = @import("std");

pub const Token = struct {
    kind: Kind,
    lexeme: []const u8,
    location: Location,

    pub const Location = struct {
        start: usize,
        end: usize,
    };
    pub const Kind = enum {
        eof,
        identifier,
        string_literal,
        number_literal,
        float_literal,
        char_literal,
        // Types
        int,
        float,
        char,
        string,
        bool,
        //Keywords
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
        // Operators
        Mul,
        MulEqual,
        Div,
        Mod,
        Add,
        AddEqual,
        Sub,
        SubEqual,
        LessThan,
        GreaterThan,
        LessThanEqual,
        GreaterThanEqual,
        EqualEqual,
        BangEqual,
        Equal,
        Bang,
        QuestionMark,
        // delimiters
        comma,
        semicolon,
        colon,
        dot,
        // Punctuators
        LeftParen,
        RightParen,
        LeftBrace,
        RightBrace,
        LeftBracket,
        RightBracket,
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
        std.debug.print("{s} \"{s}\"\n", .{ @tagName(token.kind), token.lexeme });
    }

    pub fn init(source: []const u8) Tokenizer {
        return Tokenizer{
            .source = source,
            .index = 0,
            .current_token = null,
            .Allocation = std.heap.ArenaAllocator.init(std.heap.page_allocator),
        };
    }

    pub fn isWhitespace(self: *Tokenizer, char: u8) bool {
        _ = self;
        return char == ' ' or char == '\t' or char == '\r' or char == '\n';
    }

    pub fn isDigit(self: *Tokenizer, char: u8) bool {
        _ = self;
        return char >= '0' and char <= '9';
    }

    pub fn isAlpha(self: *Tokenizer, char: u8) bool {
        _ = self;
        return (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z');
    }

    pub fn isPunctuator(self: *Tokenizer, char: u8) bool {
        _ = self;
        return char == ':' or char == '(' or char == ')' or char == '{' or char == '}' or char == ';';
    }

    pub fn tokenize(self: *Tokenizer) !std.ArrayList(Token) {
        var tokens = std.ArrayList(Token).init(self.Allocation.allocator());
        var index: usize = 0;

        while (index < self.source.len) {
            var result: Token = Token{
                .kind = .eof,
                .lexeme = "",
                .location = .{ .start = index, .end = index },
            };

            switch (self.source[index]) {
                ':' => {
                    result.kind = .colon;
                    result.lexeme = ":";
                    index += 1;
                },
                '(' => {
                    result.kind = .LeftParen;
                    result.lexeme = "(";
                    index += 1;
                },
                ')' => {
                    result.kind = .RightParen;
                    result.lexeme = ")";
                    index += 1;
                },
                '{' => {
                    result.kind = .LeftBrace;
                    result.lexeme = "{";
                    index += 1;
                },
                '}' => {
                    result.kind = .RightBrace;
                    result.lexeme = "}";
                    index += 1;
                },
                '[' => {
                    result.kind = .LeftBracket;
                    result.lexeme = "[";
                    index += 1;
                },
                ']' => {
                    result.kind = .RightBracket;
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
                    result.kind = .dot;
                    result.lexeme = ".";
                    index += 1;
                },
                '+' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "+=";
                        result.kind = .AddEqual;
                        index += 2;
                    } else {
                        result.kind = .Add;
                        result.lexeme = "+";
                        index += 1;
                    }
                },
                '-' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "-=";
                        result.kind = .SubEqual;
                        index += 2;
                    } else {
                        result.kind = .Sub;
                        result.lexeme = "-";
                        index += 1;
                    }
                },

                '*' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "*=";
                        result.kind = .MulEqual;
                        index += 2;
                    } else {
                        result.kind = .Mul;
                        result.lexeme = "*";
                        index += 1;
                    }
                },
                '/' => {
                    result.kind = .Div;
                    result.lexeme = "/";
                    index += 1;
                },
                '%' => {
                    result.kind = .Mod;
                    result.lexeme = "%";
                    index += 1;
                },
                '<' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "<=";
                        result.kind = .LessThanEqual;
                        index += 2;
                    } else {
                        result.kind = .LessThan;
                        result.lexeme = "<";
                        index += 1;
                    }
                },
                '>' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = ">=";
                        result.kind = .GreaterThanEqual;
                        index += 2;
                    } else {
                        result.kind = .GreaterThan;
                        result.lexeme = ">";
                        index += 1;
                    }
                },
                '=' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "==";
                        result.kind = .EqualEqual;
                        index += 2;
                    } else {
                        result.kind = .Equal;
                        result.lexeme = "=";
                        index += 1;
                    }
                },
                '!' => {
                    if (index + 1 < self.source.len and self.source[index + 1] == '=') {
                        result.lexeme = "!=";
                        result.kind = .BangEqual;
                        index += 2;
                    } else {
                        result.kind = .Bang;
                        result.lexeme = "!";
                        index += 1;
                    }
                },
                '?' => {
                    result.kind = .QuestionMark;
                    result.lexeme = "?";
                    index += 1;
                },
                '#' => {
                    while (index < self.source.len and self.source[index] != '\n') : (index += 1) {}
                },
                '0'...'9' => {
                    var isFloat = false;
                    var start = index;
                    while (index < self.source.len and ((self.source[index] >= '0' and self.source[index] <= '9') or
                        (self.source[index] == '.' and !isFloat))) : (index += 1)
                    {
                        if (self.source[index] == '.') {
                            isFloat = true;
                            index += 1;
                        }
                    }
                    if (isFloat) {
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
                        if (result.lexeme.len != 1 or result.lexeme.len == 0) {
                            return error.not_a_char;
                        }
                        result.kind = .char_literal;
                        index += 1;
                    } else {
                        return error.unterminated_char_literal;
                    }
                },
                'a'...'z', 'A'...'Z' => {
                    while ((self.source[index] >= 'a' and self.source[index] <= 'z' or self.source[index] >= 'A' and self.source[index] <= 'Z') and !self.isPunctuator(self.source[index])) : (index += 1) {}
                    result.lexeme = self.source[result.location.start..index];
                    if (Token.getKeyword(result.lexeme)) |kind| {
                        result.kind = kind;
                    } else {
                        result.kind = .identifier;
                    }
                },
                '"' => {
                    var start = index;
                    index += 1;
                    while (index < self.source.len) {
                        if (self.source[index] == '"') {
                            index += 1;
                            break;
                        }
                        index += 1;
                    }
                    result.lexeme = self.source[start + 1 .. index - 1];
                    result.kind = .string_literal;
                },

                else => {
                    index += 1;
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
        } });
        self.tokens_count += 1;
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
    try testTokenize("let x: char = 'a';", &.{ .keyword_let, .identifier, .colon, .char, .Equal, .char_literal, .semicolon });
}

test "Numbers" {
    try testTokenize("let x: float = 1.0;", &.{ .keyword_let, .identifier, .colon, .float, .Equal, .float_literal, .semicolon });
    try testTokenize("let y: int = 1;", &.{ .keyword_let, .identifier, .colon, .int, .Equal, .number_literal, .semicolon });

    try testTokenize("123456789", &.{.number_literal});
}

test "string" {
    try testTokenize("let x: string = \"foo\";", &.{ .keyword_let, .identifier, .colon, .string, .Equal, .string_literal, .semicolon });
}

test "operators" {
    try testTokenize("+=", &.{.AddEqual});
    try testTokenize("+", &.{.Add});

    try testTokenize("-=", &.{.SubEqual});
    try testTokenize("-", &.{.Sub});

    try testTokenize("*=", &.{.MulEqual});
    try testTokenize("*", &.{.Mul});

    try testTokenize("/", &.{.Div});

    try testTokenize("%", &.{.Mod});

    try testTokenize("<", &.{.LessThan});
    try testTokenize("<=", &.{.LessThanEqual});

    try testTokenize(">", &.{.GreaterThan});
    try testTokenize(">=", &.{.GreaterThanEqual});

    try testTokenize("==", &.{.EqualEqual});
    try testTokenize("=", &.{.Equal});

    try testTokenize("!=", &.{.BangEqual});
}
