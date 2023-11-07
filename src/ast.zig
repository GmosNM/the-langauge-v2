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

pub const FunctionCall = struct {
    name: []const u8,
    args: std.ArrayList(VariableRef),
};

pub const VariableRef = struct {
    name: []const u8,
};

pub const Expr = union(enum) {
    VariableReference: VariableRef,
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
    VariableReference: VariableRef,
    FunctionCall: FunctionCall,
};

pub const ReturnStmt = struct {
    Value: Expression,
};

pub const VariableReference = struct {
    name: []const u8,
    value_type: Types,
    value: Expression,
};

pub const Node = union(enum) {
    Leaf: i32,
    VariableDecl: VariableDecl,
    VariableReference: VariableReference,
    FunctionDecl: FunctionDecl,
    FunctionCall: FunctionCall,
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
                    var t = @tagName(variable.Type);
                    var value = variable.value;
                    std.debug.print("{s}: \n\tname: {s}\n", .{ @tagName(node), name });
                    std.debug.print("\tType: {s}\n", .{t});
                    switch (value) {
                        .BinaryExpr => |binaryExpr| {
                            var left = binaryExpr.left;
                            var right = binaryExpr.right;
                            var operator = @tagName(binaryExpr.operator);
                            switch (left) {
                                .VariableReference => |vars| {
                                    var vs_name = vars.name;
                                    std.debug.print("\tLeft: name: {s},\n", .{vs_name});
                                },
                                .LiteralExpr => |literalExpr| {
                                    var expr_value = literalExpr.value;
                                    std.debug.print("\tLeft: Value: {s}\n", .{expr_value});
                                },
                            }
                            std.debug.print("\tOperator: {s}\n", .{operator});
                            switch (right) {
                                .VariableReference => |vars| {
                                    var vs_name = vars.name;
                                    std.debug.print("\tRight: name: {s},\n", .{vs_name});
                                },
                                .LiteralExpr => |literalExpr| {
                                    var expr_value = literalExpr.value;
                                    std.debug.print("\tRight: Value: {s}\n", .{expr_value});
                                },
                            }
                        },
                        .LiteralExpr => |literalExpr| {
                            var expr_value = literalExpr.value;
                            std.debug.print("\tValue: {s}\n", .{expr_value});
                        },
                        else => {},
                    }
                },
                .VariableReference => |variable| {
                    var v_type = @tagName(variable.value_type);
                    std.debug.print("\n\tType: {s}\n", .{v_type});
                },
                .FunctionCall => |functionCall| {
                    var name = functionCall.name;
                    std.debug.print("{s}: \n\tname: {s}\n", .{ @tagName(node), name });
                    for (functionCall.args.items) |arg| {
                        var arg_name = arg.name;
                        std.debug.print("\targ_name: {s}\n", .{arg_name});
                    }
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
                                var value = variable.value;
                                std.debug.print("\t\t\tVariable: {s}\n", .{variable.name});
                                switch (value) {
                                    .BinaryExpr => |binaryExpr| {
                                        var left = binaryExpr.left;
                                        var right = binaryExpr.right;
                                        var operator = @tagName(binaryExpr.operator);
                                        switch (left) {
                                            .VariableReference => |vars| {
                                                var vs_name = vars.name;
                                                std.debug.print("\t\t\tLeft: name: {s},\n", .{vs_name});
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
                                                std.debug.print("\t\t\tRight::Variable: {s},\n", .{vs_name});
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
                                    .FunctionCall => |functionCall| {
                                        name = functionCall.name;
                                        std.debug.print("\t\t\tFunctionCall::{s}:: \n", .{name});
                                        for (functionCall.args.items) |arg| {
                                            var arg_name = arg.name;
                                            std.debug.print("\t\t\t\targ_name: {s}\n", .{arg_name});
                                        }
                                    },
                                    else => {},
                                }
                            },
                            .VariableReference => |variable| {
                                var v_name = variable.name;
                                var value = variable.value;
                                std.debug.print("\t\tVariableReference:\n\t\t\tname: {s}\n", .{v_name});
                                switch (value) {
                                    .BinaryExpr => |binaryExpr| {
                                        var left = binaryExpr.left;
                                        var right = binaryExpr.right;
                                        var operator = @tagName(binaryExpr.operator);
                                        switch (left) {
                                            .VariableReference => |vars| {
                                                var vs_name = vars.name;
                                                std.debug.print("\t\t\tLeft: name: {s},\n", .{vs_name});
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                std.debug.print("\t\t\tvalue_type: {s}\n", .{@tagName(variable.value_type)});
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tLeft: Value: {s}\n", .{expr_value});
                                            },
                                        }
                                        std.debug.print("\t\t\tOperator: {s}\n", .{operator});
                                        switch (right) {
                                            .VariableReference => |vars| {
                                                var vs_name = vars.name;
                                                std.debug.print("\t\t\tRight: name: {s},\n", .{vs_name});
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
                                                std.debug.print("\t\t\tLeft: Value: {s}\n", .{v_name});
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tLeft: Value: {s}\n", .{expr_value});
                                            },
                                        }
                                        std.debug.print("\t\t\tOperator: {s}\n", .{operator});
                                        switch (right) {
                                            .VariableReference => |variable| {
                                                std.debug.print("\t\t\tRight: {s}: Value: {s}\n", .{ @tagName(body_node), variable.name });
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
                                    .FunctionCall => |functionCall| {
                                        var name_f = functionCall.name;
                                        std.debug.print("\t\t\tLeft: Value: {s}\n", .{name_f});
                                        for (functionCall.args.items) |arg| {
                                            var arg_name = arg.name;
                                            std.debug.print("\t\t\t\targ_name: {s}\n", .{arg_name});
                                        }
                                    },
                                    .UnaryExpr => |unaryExpr| {
                                        var operand = unaryExpr.operand;
                                        var operator = @tagName(unaryExpr.operator);
                                        std.debug.print("\t\t\tOperator: {s}\n", .{operator});
                                        switch (operand) {
                                            .VariableReference => |variable| {
                                                var v_name = variable.name;
                                                std.debug.print("\t\t\tValue: {s}\n", .{v_name});
                                            },
                                            .LiteralExpr => |literalExpr| {
                                                var expr_value = literalExpr.value;
                                                std.debug.print("\t\t\tValue: {s}\n", .{expr_value});
                                            },
                                        }
                                    },
                                    .VariableReference => |variable| {
                                        std.debug.print("\t\t\tValue: {s}\n", .{variable.name});
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
