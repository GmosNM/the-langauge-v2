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

fn analyzeBody(self: *this, func_: function_decl) !void {
    var function_index: usize = 0;
    var function_scope = try self.symbol_table.createScope(func_.name);
    while (function_index < func_.body.body.items.len) : (function_index += 1) {
        switch (func_.body.body.items[function_index]) {
            .VariableDecl => |var_| {
                if (function_scope.hasVariable(var_.name)) {
                    try self.parser.PrintError();
                    std.debug.print("Variable {s} already declared\n", .{var_.name});
                    return error.DuplicateVariable;
                }
                try function_scope.addVariable(var_.name, var_.Type, var_.value.LiteralExpr.value);
            },
            .VariableReference => |var_| {
                var v = function_scope.getVariable(var_.name);
                if (v.?.type != var_.value_type) {
                    try self.parser.PrintError();
                    std.debug.print("Type mismatch\n", .{});
                    return error.TypeMismatch;
                }
            },
            else => {},
        }
    }
    try self.symbol_table.exitScope(function_scope);
}

pub fn analyze(self: *this, tree: ast) !void {
    var global_scope = try self.symbol_table.createScope("global");
    self.symbol_table.SetGlobalScope(global_scope);
    while (self.index < tree.nodes.items.len) : (self.index += 1) {
        switch (tree.nodes.items[self.index]) {
            .VariableDecl => |var_| {
                if (global_scope.hasVariable(var_.name)) {
                    try self.parser.PrintError();
                    std.debug.print("Variable {s} already declared\n", .{var_.name});
                }
                try global_scope.addVariable(var_.name, var_.Type, var_.value.LiteralExpr.value);
            },
            .VariableReference => |var_| {
                var v = global_scope.getVariable(var_.name) orelse return error.VariableNotDeclared;
                if (v.type != var_.value_type) {
                    try self.parser.PrintError();
                    std.debug.print("Type mismatch\n", .{});
                    return error.TypeMismatch;
                }
                v.value = var_.value.LiteralExpr.value;
            },
            .FunctionDecl => |func_| {
                try global_scope.addFunction(func_.name, func_.args, func_.return_type);
                try self.analyzeBody(func_);
            },
            else => {},
        }
    }
    try self.symbol_table.exitScope(global_scope);
    self.symbol_table.printall();
    self.index = 0;
    for (global_scope.Functions.items) |func| {
        if (std.mem.eql(u8, func.name, "main")) {} else {
            std.debug.print("Function main not found\n", .{});
            return error.noEntryPoint;
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
const Symbol_table = @import("symbol_table.zig");
const function_decl = @import("ast.zig").FunctionDecl;
