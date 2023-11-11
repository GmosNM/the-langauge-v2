const std = @import("std");
const parser = @import("parser.zig").Parser;
const semantic = @import("sema.zig");
const ir = @import("ir.zig");
const codegen = @import("codegen.zig");

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

    var irgen = try ir.init(alloc.allocator(), &par, sema.symbol_table);
    try irgen.genIR(par.ast);

    var gen = try codegen.init(alloc.allocator(), irgen.getIR());
    try gen.init_codegen();
    try gen.codegen();

    defer par.deinit();
    defer sema.deinit();
}

test "tests" {
    _ = @import("lexer.zig");
    _ = @import("parser.zig");
}
