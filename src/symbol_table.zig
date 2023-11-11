const symbol_table = @This();
const std = @import("std");
const mem = std.mem;
const ast = @import("ast.zig");

Scope_stack: std.ArrayList(Scope),
current_scope: Scope,
alloc: std.mem.Allocator,
global_scope: Scope,

const Scope = struct {
    name: []const u8,
    Variables: std.ArrayList(Variable),
    Functions: std.ArrayList(Function),

    pub fn hasVariable(self: Scope, name: []const u8) bool {
        for (self.Variables.items) |variable| {
            if (mem.eql(u8, variable.name, name)) {
                return true;
            }
        }
        return false;
    }

    pub fn hasFunction(self: Scope, name: []const u8) bool {
        for (self.Functions.items) |function| {
            if (mem.eql(u8, function.name, name)) {
                return true;
            }
        }
        return false;
    }

    pub fn getVariable(self: Scope, name: []const u8) ?Variable {
        for (self.Variables.items) |variable| {
            if (mem.eql(u8, variable.name, name)) {
                return variable;
            }
        }
        return null;
    }

    pub fn getFunction(self: Scope, name: []const u8) ?Function {
        for (self.Functions.items) |function| {
            if (mem.eql(u8, function.name, name)) {
                return function;
            }
        }
    }

    pub fn print(self: Scope) void {
        std.debug.print("Scope: {s}\n", .{self.name});
        for (self.Variables.items) |variable| {
            std.debug.print("Variable: {s}\n", .{variable.name});
        }
        for (self.Functions.items) |function| {
            std.debug.print("Function: {s}\n", .{function.name});
        }
    }

    pub fn addVariable(self: *Scope, name: []const u8, type_: ast.Types, value: ?[]const u8) !void {
        try self.Variables.append(Variable{ .name = name, .type = type_, .value = value });
    }

    pub fn addFunction(self: *Scope, name: []const u8, args: std.ArrayList(ast.VariableDecl), return_type: ast.Types) !void {
        try self.Functions.append(Function{ .name = name, .args = args, .return_type = return_type });
    }

    pub fn init(allocator: mem.Allocator, name: []const u8) Scope {
        return Scope{
            .name = name,
            .Variables = std.ArrayList(Variable).init(allocator),
            .Functions = std.ArrayList(Function).init(allocator),
        };
    }
};

const Variable = struct {
    name: []const u8,
    type: ast.Types,
    value: ?[]const u8,
};

const Function = struct {
    name: []const u8,
    args: std.ArrayList(ast.VariableDecl),
    return_type: ast.Types,
};

pub fn SetGlobalScope(self: *symbol_table, scope: Scope) void {
    self.global_scope = scope;
}

pub fn init(allocator: mem.Allocator) symbol_table {
    return symbol_table{ .Scope_stack = std.ArrayList(Scope).init(allocator), .current_scope = undefined, .alloc = allocator, .global_scope = Scope{
        .name = undefined,
        .Variables = std.ArrayList(Variable).init(allocator),
        .Functions = std.ArrayList(Function).init(allocator),
    } };
}

pub fn createScope(self: *symbol_table, name: []const u8) !Scope {
    var newScope = Scope.init(self.alloc, name);
    self.current_scope = newScope;
    return newScope;
}

pub fn exitScope(self: *symbol_table, scope: Scope) !void {
    try self.Scope_stack.append(scope);
}

pub fn deinit(self: *symbol_table) void {
    for (self.Scope_stack.items) |scope| {
        scope.Variables.deinit();
        scope.Functions.deinit();
    }
}

pub fn printall(self: symbol_table) void {
    for (self.Scope_stack.items) |scope| {
        std.debug.print("Scope: {s}\n", .{scope.name});
        for (scope.Variables.items) |variable| {
            std.debug.print("Variable: {s}\n", .{variable.name});
        }
        for (scope.Functions.items) |function| {
            std.debug.print("Function: {s}\n", .{function.name});
            for (function.args.items) |arg| {
                std.debug.print("Arg: {s}\n", .{arg.name});
            }
        }
    }
}
