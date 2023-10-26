const std = @import("std");

const variable = struct { name: []const u8, value: []const u8, new_value: []u8 };

pub const symbol_table = struct {
    variables: std.ArrayList(variable),

    pub fn init(allocator: std.mem.Allocator) !symbol_table {
        return symbol_table{
            .variables = std.ArrayList(variable).init(allocator),
        };
    }

    pub fn addVariable(self: *symbol_table, name: []const u8, value: []const u8) !void {
        try self.variables.append(.{
            .name = name,
            .value = value,
            .new_value = undefined,
        });
    }

    pub fn updateVariable(self: *symbol_table, name: []const u8, value: []const u8) !void {
        for (self.variables.items) |v| {
            if (std.mem.eql(u8, v.name, name)) {
                std.mem.copy(u8, v.new_value, value);
                return;
            } else {
                std.debug.print("not found\n", .{});
            }
        }
    }

    pub fn print(self: *symbol_table) void {
        for (self.variables.items) |v| {
            std.debug.print("{s} = {s}\n", .{ v.name, v.value });
        }
    }
};
