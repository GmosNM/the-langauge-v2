const std = @import("std");
const parser = @import("parser.zig").Parser;
const semantic = @import("sema.zig");

pub fn read_file(filename: []const u8) ![]const u8 {
    var buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const result = try std.fs.cwd().readFile(filename, &buffer);
    return result;
}

pub fn main() !void {
    var source = try read_file("test.x");
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var par = try parser.init(source, "test.x", alloc.allocator());
    try par.pushAll();
    try par.parse();
    par.ast.print();

    var sema = semantic.init(alloc.allocator(), par);
    try sema.analyze(par.ast);

    defer par.deinit();
    defer sema.deinit();
}

test "tests" {
    _ = @import("lexer.zig");
    _ = @import("parser.zig");
}
