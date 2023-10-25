const std = @import("std");
const Token = @import("tokenizer.zig").Token;

const kind = Token.Kind;

pub const Node = struct {
    node_kind: Kind,

    pub const Kind = enum {
        Root,
        GlobalVarDeclaration,
        LocalVarDeclaration,
    };

    pub const LocalVarDecl = struct {
        type_node: Kind,
        value_node: Kind,
    };
};
