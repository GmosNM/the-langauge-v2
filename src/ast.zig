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
    plus_equal,
    minus,
    minus_equal,
    multiply,
    divide,
    less_than,
    less_than_equal,
    greater_than,
    greater_than_equal,
    equal,
    equal_equal,
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
    args: std.ArrayList(Expression),
};

pub const IfStmt = struct {
    condition: Expression,
    body: Body,
    else_body: ?Body,
};

pub const VariableRef = struct {
    name: []const u8,
};

pub const Expr = union(enum) {
    VariableReference: VariableRef,
    LiteralExpr: LiteralExpr,
    FunctionCall: FunctionCall,
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
    Operator: Operator,
    value: Expression,
};

pub const Node = union(enum) {
    Leaf: i32,
    VariableDecl: VariableDecl,
    VariableReference: VariableReference,
    FunctionDecl: FunctionDecl,
    FunctionCall: FunctionCall,
    IfStmt: IfStmt,
    Body: Body,
    ReturnStmt: ReturnStmt,
    Expr: Expression,
};

pub const ast = struct {
    nodes: std.ArrayList(Node),

    pub fn pushto(self: *ast, array: std.ArrayList(Node)) !void {
        for (self.nodes.items) |node| {
            try array.append(node);
        }
    }

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

    fn printNodeExpression(Self: *ast, node: Expression, taps: []const u8) void {
        switch (node) {
            .BinaryExpr => |binaryExpr| {
                var left = binaryExpr.left;
                var right = binaryExpr.right;
                var operator = @tagName(binaryExpr.operator);
                switch (left) {
                    .VariableReference => |vars| {
                        var vs_name = vars.name;
                        std.debug.print("{s}Left: name: {s},\n", .{ taps, vs_name });
                    },
                    .LiteralExpr => |literalExpr| {
                        var expr_value = literalExpr.value;
                        std.debug.print("{s}Left: Value: {s}\n", .{ taps, expr_value });
                    },
                    .FunctionCall => |functionCall| {
                        var name = functionCall.name;
                        std.debug.print("{s}Left: name: {s},\n", .{ taps, name });
                        for (functionCall.args.items) |arg| {
                            Self.printNodeExpression(arg, "\t\t\t");
                        }
                    },
                }
                std.debug.print("{s}Operator: {s}\n", .{ taps, operator });
                switch (right) {
                    .VariableReference => |vars| {
                        var vs_name = vars.name;
                        std.debug.print("{s}Right: name: {s},\n", .{ taps, vs_name });
                    },
                    .LiteralExpr => |literalExpr| {
                        var expr_value = literalExpr.value;
                        std.debug.print("{s}Right: Value: {s}\n", .{ taps, expr_value });
                    },
                    .FunctionCall => |functionCall| {
                        var name = functionCall.name;
                        std.debug.print("{s}Right: name: {s},\n", .{ taps, name });
                        for (functionCall.args.items) |arg| {
                            Self.printNodeExpression(arg, "\t\t\t");
                        }
                    },
                }
            },
            .UnaryExpr => |unaryExpr| {
                var operand = unaryExpr.operand;
                var operator = @tagName(unaryExpr.operator);
                switch (operand) {
                    .VariableReference => |vars| {
                        var vs_name = vars.name;
                        std.debug.print("{s}Operand: name: {s},\n", .{ taps, vs_name });
                    },
                    .LiteralExpr => |literalExpr| {
                        var expr_value = literalExpr.value;
                        std.debug.print("{s}Operand: Value: {s}\n", .{ taps, expr_value });
                    },
                    .FunctionCall => |functionCall| {
                        var name = functionCall.name;
                        std.debug.print("{s}Operand: name: {s},\n", .{ taps, name });
                        for (functionCall.args.items) |arg| {
                            Self.printNodeExpression(arg, "\t\t\t");
                        }
                    },
                }
                std.debug.print("{s}Operator: {s}\n", .{ taps, operator });
            },
            .LiteralExpr => |literalExpr| {
                var expr_value = literalExpr.value;
                std.debug.print("{s}Value: {s}\n", .{ taps, expr_value });
            },
            .VariableReference => |vars| {
                var vs_name = vars.name;
                std.debug.print("{s}name: {s},\n", .{ taps, vs_name });
            },
            .FunctionCall => |functionCall| {
                var name = functionCall.name;
                std.debug.print("{s}name: {s},\n", .{ taps, name });
                for (functionCall.args.items) |arg| {
                    Self.printNodeExpression(arg, "\t\t\t");
                }
            },
        }
    }

    fn printBodyNode(Self: *ast, node: Node, taps: []const u8) void {
        switch (node) {
            .Leaf => |leaf| {
                std.debug.print("{s}Leaf: {}\n", .{ taps, leaf });
            },
            .IfStmt => |ifStmt| {
                var condition = ifStmt.condition;
                var body = ifStmt.body;
                std.debug.print("{s}- IfStmt:\n \t\t Condition: \n", .{taps});
                Self.printNodeExpression(condition, "\t\t\t");
                std.debug.print("{s}- [IF]Body: \n", .{taps});
                for (body.body.items) |body_nodes| {
                    Self.printBodyNode(body_nodes, "\t\t\t");
                }
                if (ifStmt.else_body) |else_body| {
                    std.debug.print("{s}- [ELSE]Body: \n", .{taps});
                    for (else_body.body.items) |body_nodes| {
                        Self.printBodyNode(body_nodes, "\t\t\t");
                    }
                }
            },
            .VariableDecl => |variable| {
                std.debug.print("{s}VariableDecl: \n", .{taps});
                var value = variable.value;
                std.debug.print("{s}\tVariable: {s}\n", .{ taps, variable.name });
                Self.printNodeExpression(value, "\t\t\t");
            },
            .VariableReference => |variable| {
                var v_name = variable.name;
                var value = variable.value;
                var op = @tagName(variable.Operator);
                std.debug.print("{s}VariableReference:\n\t\t\tname: {s}\n", .{ taps, v_name });
                std.debug.print("{s}Operator: {s}\n", .{ taps, op });
                Self.printNodeExpression(value, "\t\t\t");
            },
            .ReturnStmt => |returnStmt| {
                std.debug.print("{s}ReturnStmt: \n", .{taps});
                var value = returnStmt.Value;
                Self.printNodeExpression(value, "\t\t\t");
            },
            .FunctionCall => |functionCall| {
                var name = functionCall.name;
                std.debug.print("{s}FunctionCall: \n\t\t\tname: {s}\n", .{ taps, name });
                for (functionCall.args.items) |arg| {
                    Self.printNodeExpression(arg, "\t\t\t");
                }
            },
            .FunctionDecl => |functionDecl| {
                var name = functionDecl.name;
                std.debug.print("{s}FunctionDecl: \n\t\t\tname: {s}\n", .{ taps, name });
                std.debug.print("{s}return_type: {s}\n", .{ taps, @tagName(functionDecl.return_type) });
                for (functionDecl.args.items) |arg| {
                    var arg_name = arg.name;
                    var t = @tagName(arg.Type);
                    std.debug.print("{s}arg_name: {s}, Type: {s}\n", .{ taps, arg_name, t });
                }
                for (functionDecl.body.body.items) |body_nodes| {
                    Self.printBodyNode(body_nodes, "\t\t\t");
                }
            },
            .Expr => |expr| {
                std.debug.print("{s}Expr: \n", .{taps});
                Self.printNodeExpression(expr, "\t\t\t");
            },
            .Body => |body| {
                std.debug.print("{s}Body: \n", .{taps});
                for (body.body.items) |body_nodes| {
                    Self.printBodyNode(body_nodes, "\t\t\t");
                }
            },
        }
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
                    Self.printNodeExpression(value, "\t\t");
                },
                .VariableReference => |variable| {
                    var v_type = @tagName(variable.value_type);
                    var v_name = variable.name;
                    std.debug.print("{s}: \n\tname: {s}\n", .{ @tagName(node), v_name });
                    std.debug.print("\tType: {s}\n", .{v_type});
                    Self.printNodeExpression(variable.value, "\t");
                },
                .FunctionCall => |functionCall| {
                    var name = functionCall.name;
                    std.debug.print("{s}: \n\tname: {s}\n", .{ @tagName(node), name });
                    for (functionCall.args.items) |arg| {
                        Self.printNodeExpression(arg, "\t\t\t");
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
                        Self.printBodyNode(body_node, "\t\t");
                    }
                },
                else => {
                    @panic("unreachable");
                },
            }
        }
    }
};
