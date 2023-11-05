const std = @import("std");

pub const Types = enum {
    int,
    float,
    char,
    void,
    bool,
    string,
};

pub const Operator = enum {
    plus,
    minus,
    multiply,
    divide,
    less_than,
    less_than_equal,
    greater_than,
    greater_than_equal,
    equal,
    not_equal,
    and_op,
    or_op,
    not,
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

pub const Expr = union(enum) {
    VariableDecl: VariableDecl,
};

pub const BinaryExpr = struct {
    left: Expr,
    operator: Operator,
    right: Expr,
};

pub const UnaryExpr = struct {
    operator: Operator,
    operand: Expr,
};

pub const LiteralExpr = struct {
    value: []const u8,
};

pub const Expression = union(enum) {
    BinaryExpr: BinaryExpr,
    UnaryExpr: UnaryExpr,
    LiteralExpr: LiteralExpr,
};

pub const ReturnStmt = struct {
    Value: Expression,
};

pub const Node = union(enum) {
    Leaf: i32,
    VariableDecl: VariableDecl,
    FunctionDecl: FunctionDecl,
    Body: Body,
    ReturnStmt: ReturnStmt,
    Expr: Expression,
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
        std.debug.print("Node Count: {d}\n", .{Self.nodes.items.len});
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
                        std.debug.print("\targ_name: {s}, Type: {s}\n", .{ arg_name, t });
                    }
                    for (function.body.body.items) |body_node| {
                        switch (body_node) {
                            .Leaf => |leaf| {
                                std.debug.print("\t\tLeaf: {}\n", .{leaf});
                            },
                            .VariableDecl => |variable| {
                                var var_name = variable.name;
                                var value = variable.value;
                                var t = @tagName(variable.Type);
                                std.debug.print("\t\t{s}: name: {s}, value: \"{s}\", Type: {s}\n", .{ @tagName(body_node), var_name, value, t });
                            },
                            .ReturnStmt => |returnStmt| {
                                std.debug.print("\t\tReturnStmt: \n", .{});
                                var value = returnStmt.Value;
                                switch (value) {
                                    .BinaryExpr => |binaryExpr| {
                                        var left = binaryExpr.left;
                                        var right = binaryExpr.right;
                                        switch (left) {
                                            .VariableDecl => |variable| {
                                                var var_name = variable.name;
                                                var t = @tagName(variable.Type);
                                                std.debug.print("\t\t\tLeft: {s}: name: {s}, Type: {s}\n", .{ @tagName(body_node), var_name, t });
                                            },
                                        }
                                        switch (right) {
                                            .VariableDecl => |variable| {
                                                var var_name = variable.name;
                                                var t = @tagName(variable.Type);
                                                std.debug.print("\t\t\tRight: {s}: name: {s}, Type: {s}\n", .{ @tagName(body_node), var_name, t });
                                            },
                                        }
                                    },
                                    .LiteralExpr => |literalExpr| {
                                        var expr_value = literalExpr.value;
                                        std.debug.print("\t\t\tValue: {s}\n", .{expr_value});
                                    },
                                    .UnaryExpr => |unaryExpr| {
                                        var operand = unaryExpr.operand;
                                        _ = operand;
                                    },
                                }
                            },
                            else => {
                                std.debug.print("\t\t{s}: \n", .{@tagName(body_node)});
                            },
                        }
                    }
                },
                else => {
                    std.debug.print("{s}: \n", .{@tagName(node)});
                },
            }
        }
    }
};
