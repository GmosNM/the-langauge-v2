const IR = @import("ir.zig");
const std = @import("std");

const Variable = struct {
    name: []const u8,
    value: []const u8,
};

const Function = struct {
    name: []const u8,
    args: std.ArrayList(Variable),
    body: []const IR.ir_instruction,
};

fn to_slice(pointer: [*]u8, len: usize) []u8 {
    return pointer[0..len];
}

const Codegen = struct {
    alloc: std.mem.Allocator,
    ir: std.ArrayList(IR.ir_instruction),
    data_section: std.ArrayList(Variable),
    check_section: std.ArrayList(Variable),
    labels: std.ArrayList([]const u8),

    // push data to the sections
    pub fn init_codegen(Self: *Codegen) !void {
        for (Self.ir.items) |item| {
            switch (item) {
                .VariableDecl => |vare| {
                    var v = Variable{
                        .name = vare.name,
                        .value = vare.init.?,
                    };
                    try Self.data_section.append(v);
                },
                .VariableAssign => {
                    var new = Variable{
                        .name = item.VariableAssign.name,
                        .value = item.VariableAssign.value,
                    };
                    try Self.check_section.append(new);
                },
                .FunctionDecl => |func| {
                    var name = func.name;
                    try Self.labels.append(name);
                },
            }
        }
    }

    pub fn codegen(Self: *Codegen) !void {
        std.debug.print("section .data\n", .{});
        for (Self.data_section.items) |item| {
            std.debug.print("  {s}: db {s} ;; init the value of {s}\n", .{ item.name, item.value, item.name });
        }
        std.debug.print("section .text\n", .{});
        std.debug.print("global _start\n", .{});
        std.debug.print("_start:\n", .{});
        for (Self.check_section.items) |item| {
            for (Self.data_section.items) |data| {
                if (std.mem.eql(u8, item.name, data.name)) {
                    std.debug.print("  mov dword [{s}], {s}\n", .{ data.name, item.value });
                } else {
                    std.debug.print("  mov dword [{s}], {s}\n", .{ data.name, data.value });
                }
            }
        }
        for (Self.labels.items) |label| {
            std.debug.print("{s}:\n", .{label});
        }
    }
};

pub fn init(alloc: std.mem.Allocator, ir: std.ArrayList(IR.ir_instruction)) !Codegen {
    return .{
        .ir = ir,
        .alloc = alloc,
        .data_section = std.ArrayList(Variable).init(alloc),
        .check_section = std.ArrayList(Variable).init(alloc),
        .labels = std.ArrayList([]const u8).init(alloc),
    };
}
