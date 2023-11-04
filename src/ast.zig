const std = @import("std");

pub const Types = enum {
    int,
    float,
    char,
    void,
    bool,
    string,
};

pub const VariableDecl = struct {
    name: []const u8,
    Type: Types,
    value: []const u8,
};

pub const Node = union(enum) {
    Leaf: i32,
    VariableDecl: VariableDecl,
};

pub const ast = struct {
    nodes: std.ArrayList(Node),

    pub fn init(allocator: std.mem.Allocator) ast {
        return .{
            .nodes = std.ArrayList(Node).init(allocator),
        };
    }

    pub fn deinit(Self: *ast) void {
        Self.nodes.deinit();
    }

    pub fn push(Self: *ast, node: Node) !void {
        try Self.nodes.append(node);
    }

    pub fn print(Self: *ast) void {
        for (Self.nodes.items) |node| {
            switch (node) {
                .Leaf => |leaf| {
                    std.debug.print("Leaf: {}\n", .{leaf});
                },
                .VariableDecl => |variable| {
                    var name = variable.name;
                    var value = variable.value;
                    var t = @tagName(variable.Type);
                    std.debug.print("{s}: name: {s}, value: \"{s}\", Type: {s}\n", .{ @tagName(node), name, value, t });
                },
            }
        }
    }
};
