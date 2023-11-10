gpa: std.mem.Allocator,
parser: Parser,
symbol_table: Symbol_table,
index: usize = 0,

pub fn init(gpa: std.mem.Allocator, parser: Parser) this {
    return .{
        .gpa = gpa,
        .parser = parser,
        .symbol_table = Symbol_table.init(gpa),
    };
}

pub fn analyze(self: *this, tree: ast) !void {
    var global_scope = try self.symbol_table.createScope("global");
    self.symbol_table.SetGlobalScope(global_scope);
    while (self.index < tree.nodes.items.len) : (self.index += 1) {
        switch (tree.nodes.items[self.index]) {
            .VariableDecl => |var_| {
                try global_scope.addVariable(var_.name, var_.Type, var_.value.LiteralExpr.value);
            },
            .FunctionDecl => |func_| {
                try global_scope.addFunction(func_.name, func_.args, func_.return_type);
                var function_scope = try self.symbol_table.createScope(func_.name);
                for (func_.args.items) |arg| {
                    try function_scope.addVariable(arg.name, arg.Type, null);
                }
                var function_index: usize = 0;
                while (function_index < func_.body.body.items.len) : (function_index += 1) {
                    switch (func_.body.body.items[function_index]) {
                        .VariableDecl => |var_| {
                            try function_scope.addVariable(var_.name, var_.Type, var_.value.LiteralExpr.value);
                        },
                        else => {},
                    }
                }
                try self.symbol_table.exitScope(function_scope);
            },
            else => {},
        }
    }
    try self.symbol_table.exitScope(global_scope);
    self.symbol_table.printall();
    self.index = 0;
}

pub fn deinit(self: *this) void {
    self.symbol_table.deinit();
}

const this = @This();
const std = @import("std");
const Parser = @import("parser.zig").Parser;
const ast = @import("ast.zig").ast;
const Node = @import("ast.zig").Node;
const Symbol_table = @import("symbol_table.zig");
