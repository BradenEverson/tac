//! Core Parser and AST definition

pub const Expr = union(enum) {
    assignment: struct { name: []const u8, val: *Expr },
    binary_op: struct { left: *Expr, op: BinaryOp, right: *Expr },
    literal: Literal,
};

pub const Literal = union(enum) {
    number: i64,
};

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    div,
};
