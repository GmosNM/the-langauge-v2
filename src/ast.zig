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
    value: Expression,
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
    VariableReference: VariableReference,
    LiteralExpr: LiteralExpr,
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
    VariableReference: VariableReference,
};

pub const ReturnStmt = struct {
    Value: Expression,
};

pub const VariableReference = struct {
    name: []const u8,
    value_type: Types,
};

pub const Node = union(enum) {
    Leaf: i32,
    VariableDecl: VariableDecl,
    VariableReference: VariableReference,
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
                    _ = variable;
                },
                .VariableReference => |variable| {
                    var v_name = variable.name;
                    var v_type = @tagName(variable.value_type);
                    std.debug.print("{s}: name: {s}, Type: {s}\n", .{ @tagName(node), v_name, v_type });
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
                                std.debug.print("\t\tVariableDecl: \n", .{});
                                var v_name = variable.name;
                                _ = v_name;
                                var value = variable.value;
                                switch (value) {
                                    .BinaryExpr => |binaryExpr| {
                                        var left = binaryExpr.left;
                                        var right = binaryExpr.right;
                                        var operator = @tagName(binaryExpr.operator);
                                        switch (left) {
                                            .VariableReference => |vars| {
                                                var vs_name = vars.name;
                                                var v_type = @tagName(vars.value_type);
                                                std.debug.print("\t\t\tLeft: name: {s}, ValueType: {s}\n", .{ vs_name, v_type });
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tLeft: Value: {s}\n", .{expr_value});
                                            },
                                        }
                                        std.debug.print("\t\t\tOperator: {s}\n", .{operator});
                                        switch (right) {
                                            .VariableReference => |vars| {
                                                var vs_name = vars.name;
                                                var v_type = @tagName(vars.value_type);
                                                std.debug.print("\t\t\tRight: name: {s}, ValueType: {s}\n", .{ vs_name, v_type });
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tRight: Value: {s}\n", .{expr_value});
                                            },
                                        }
                                    },
                                    .LiteralExpr => |literalExpr| {
                                        var expr_value = literalExpr.value;
                                        std.debug.print("\t\t\tValue: {s}\n", .{expr_value});
                                    },
                                    else => {},
                                }
                            },
                            .VariableReference => |variable| {
                                var v_name = variable.name;
                                var v_type = @tagName(variable.value_type);
                                std.debug.print("\t\t{s}: name: {s}, ValueType: {s}\n", .{ @tagName(body_node), v_name, v_type });
                            },
                            .ReturnStmt => |returnStmt| {
                                std.debug.print("\t\tReturnStmt: \n", .{});
                                var value = returnStmt.Value;
                                switch (value) {
                                    .BinaryExpr => |binaryExpr| {
                                        var left = binaryExpr.left;
                                        var right = binaryExpr.right;
                                        var operator = @tagName(binaryExpr.operator);
                                        switch (left) {
                                            .VariableReference => |variable| {
                                                var v_name = variable.name;
                                                var v_type = @tagName(variable.value_type);
                                                std.debug.print("\t\t\tLeft: {s}: name: {s}, ValueType: {s}\n", .{ @tagName(body_node), v_name, v_type });
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tLeft: {s}: Value: {s}\n", .{ @tagName(body_node), expr_value });
                                            },
                                        }
                                        std.debug.print("\t\t\tOperator: {s}\n", .{operator});
                                        switch (right) {
                                            .VariableReference => |variable| {
                                                var v_name = variable.name;
                                                var v_type = @tagName(variable.value_type);
                                                std.debug.print("\t\t\tRight: {s}: name: {s}, ValueType: {s}\n", .{ @tagName(body_node), v_name, v_type });
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tRight: {s}: Value: {s}\n", .{ @tagName(body_node), expr_value });
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
                                    .VariableReference => |variable| {
                                        var v_name = variable.name;
                                        var v_type = @tagName(variable.value_type);
                                        std.debug.print("\t\t\tVariableReference: name: {s}, ValueType: {s}\n", .{ v_name, v_type });
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
