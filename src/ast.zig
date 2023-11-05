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

pub const Body = struct {
    body: std.ArrayList(Node),
};

pub const FunctionDecl = struct {
    name: []const u8,
    args: std.ArrayList(VariableDecl),
    return_type: Types,
    body: Body,
};

pub const Node = union(enum) {
    Leaf: i32,
    VariableDecl: VariableDecl,
    FunctionDecl: FunctionDecl,
    Body: Body,
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
                .FunctionDecl => |function| {
                    var name = function.name;
                    std.debug.print("{s}: \n\tname: {s}\n", .{ @tagName(node), name });
                    std.debug.print("\treturn_type: {s}\n", .{@tagName(function.return_type)});
                    for (function.args.items) |arg| {
                        var arg_name = arg.name;
                        var t = @tagName(arg.Type);
                        std.debug.print("\t{s}: name: {s}, Type: {s}\n", .{ @tagName(node), arg_name, t });
                    }
                    for (function.body.body.items) |body_node| {
                        std.debug.print("{s}: \n", .{@tagName(body_node)});
                    }
                },
                .Body => |body| {
                    std.debug.print("{s}: \n", .{@tagName(node)});
                    for (body.body.items) |body_node| {
                        std.debug.print("{s}: \n", .{@tagName(body_node)});
                    }
                },
            }
        }
    }
};
