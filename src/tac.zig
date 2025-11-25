//! Three Address Codes for translating an AST into an IR

const parser = @import("parser.zig");
const Literal = parser.Literal;
const BinaryOp = parser.BinaryOp;

pub const ThreeAddressCode = union(enum) {
    value: Literal,
    binary: struct { left: Operand, op: BinaryOp, right: Operand },
};

pub const Operand = union(enum) {
    /// A constant literal (i.e. t1 = 10)
    literal: Literal,
    /// A reference to a previous TAC (i.e. t2 = t1 * 5)
    reference: usize,
};
