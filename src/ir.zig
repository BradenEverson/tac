//! Three Address Codes for translating an AST into an IR

const std = @import("std");

const parser = @import("parser.zig");
const Literal = parser.Literal;
const BinaryOp = parser.BinaryOp;
const Expr = parser.Expr;

pub const ThreeAddressCode = union(enum) {
    /// A raw value assignment to either a literal or a previous variable
    value: Literal,
    /// A binary operation assignment
    binary: struct { left: Operand, op: BinaryOp, right: Operand },
};

pub const Operand = union(enum) {
    /// A constant literal (i.e. t1 = 10)
    literal: Literal,
    /// A reference to a previous TAC (i.e. t2 = t1 * 5)
    reference: usize,
};

pub const TacIrGenerator = struct {
    ir_stream: std.ArrayList(ThreeAddressCode),
    alloc: std.mem.Allocator,

    ast: []const Expr,

    pub fn init(alloc: std.mem.Allocator, ast: []const Expr) TacIrGenerator {
        return TacIrGenerator{
            .ir_stream = std.ArrayList(ThreeAddressCode){},
            .alloc = alloc,
            .ast = ast,
        };
    }

    pub fn deinit(self: *TacIrGenerator) void {
        self.ir_stream.deinit(self.alloc);
    }

    pub fn generate(self: *TacIrGenerator) !void {
        _ = self;
    }
};

test "Init generator" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    const ast: [0]Expr = .{};

    var ir_g = TacIrGenerator.init(alloc, &ast);
    defer ir_g.deinit();
}
