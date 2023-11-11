gpa: std.mem.Allocator,
parser: Parser,
symbol_table: Symbol_table,
index: usize = 0,
output: []u8 = "",
IR: std.ArrayList(ir_instruction),

const ir_types = enum {
    i32,
    f32,
    void,
    bool,
    u8,
};

pub const ir_instruction = union(enum) { VariableDecl: struct {
    name: []const u8,
    type: ir_types,
    init: ?[]const u8,
}, VariableAssign: struct {
    name: []const u8,
    value: []const u8,
}, FunctionDecl: struct {
    name: []const u8,
    params: std.ArrayList(vv.VariableDecl),
    body: std.ArrayList(ir_instruction),
} };

pub fn getIR(self: *this) std.ArrayList(ir_instruction) {
    return self.IR;
}

pub fn init(gpa: std.mem.Allocator, parser: *Parser, sy: Symbol_table) !this {
    return .{
        .gpa = gpa,
        .parser = parser.*,
        .symbol_table = sy,
        .IR = std.ArrayList(ir_instruction).init(gpa),
    };
}

pub fn genIR(self: *this, tree: ast) !void {
    while (self.index < tree.nodes.items.len) : (self.index += 1) {
        switch (tree.nodes.items[self.index]) {
            .VariableDecl => |var_| {
                try self.IR.append(.{
                    .VariableDecl = .{
                        .name = var_.name,
                        .type = .i32,
                        .init = var_.value.LiteralExpr.value,
                    },
                });
            },
            .VariableReference => |var_| {
                try self.IR.append(.{
                    .VariableAssign = .{
                        .name = var_.name,
                        .value = var_.value.LiteralExpr.value,
                    },
                });
            },
            .FunctionDecl => |func_| {
                try self.IR.append(.{
                    .FunctionDecl = .{
                        .name = func_.name,
                        .params = func_.args,
                        .body = undefined,
                    },
                });
            },
            else => {},
        }
    }
    self.index = 0;
    for (self.IR.items) |ir| {
        switch (ir) {
            .VariableDecl => |var_| {
                _ = var_;
            },
            .VariableAssign => |var_| {
                _ = var_;
            },
            .FunctionDecl => |func_| {
                _ = func_;
            },
        }
    }
}

pub fn deinit(self: *this) void {
    self.symbol_table.deinit();
}

const this = @This();
const std = @import("std");
const Parser = @import("parser.zig").Parser;
const ast = @import("ast.zig").ast;
const Node = @import("ast.zig").Node;
const vv = @import("ast.zig");
const Symbol_table = @import("symbol_table.zig");
