const std = @import("std");
const tokenizer = @import("tokenizer.zig").Tokenizer;

pub fn read_file(filename: []const u8) ![]const u8 {
    var buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const result = try std.fs.cwd().readFile(filename, &buffer);
    return result;
}

pub fn main() !void {
    var source = try read_file("test.x");
    var tok = tokenizer.init(source);
    var token = try tok.tokenize();
    for (token.items) |t| {
        tok.dump(&t);
    }
}

test "tokenize" {
    _ = @import("tokenizer.zig");
}
