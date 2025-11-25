//! Three Address Codes for translating an AST into an IR

const std = @import("std");

const parser = @import("parser.zig");
const Literal = parser.Literal;
const BinaryOp = parser.BinaryOp;
const Expr = parser.Expr;

pub const ThreeAddressCode = struct {
    op: Operator,
    arg1: Operand,
    arg2: Operand,
};

pub const Operator = union(enum) {
    binary_op: BinaryOp,
    assignment,
};

pub const Operand = union(enum) {
    /// A constant literal (i.e. t1 = 10)
    literal: Literal,
    /// A reference to a previous TAC (i.e. t2 = t1 * 5)
    reference: usize,
    /// A variable tag (i.e. "a")
    variable: []const u8,
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

    pub fn generate_single(self: *TacIrGenerator, expr: *const Expr) !Operand {
        switch (expr.*) {
            .assignment => |a| {
                const val = try self.generate_single(a.val);

                const code = ThreeAddressCode{ .op = .assignment, .arg1 = .{ .variable = a.name }, .arg2 = val };

                try self.ir_stream.append(self.alloc, code);

                return .{ .variable = a.name };
            },

            .binary_op => |b| {
                const left = try self.generate_single(b.left);
                const right = try self.generate_single(b.right);

                const code = ThreeAddressCode{ .op = .{ .binary_op = b.op }, .arg1 = left, .arg2 = right };

                try self.ir_stream.append(self.alloc, code);

                return .{ .reference = self.ir_stream.items.len - 1 };
            },

            .literal => |l| {
                return .{ .literal = l };
            },
        }
    }

    pub fn generate(self: *TacIrGenerator) !void {
        for (self.ast) |expr| {
            _ = try self.generate_single(&expr);
        }
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

test "Test a simple AST" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    const ast = [1]Expr{.{ .literal = .{ .number = 10 } }};

    var ir_g = TacIrGenerator.init(alloc, &ast);
    defer ir_g.deinit();

    try ir_g.generate();

    try std.testing.expectEqual(0, ir_g.ir_stream.items.len);
}

test "Test a simple binary op AST" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const a: Expr = .{ .literal = .{ .number = 1 } };
    const b: Expr = .{ .literal = .{ .number = 2 } };

    const binop: Expr = .{ .binary_op = .{ .left = &a, .op = .add, .right = &b } };

    const ast = [1]Expr{binop};

    var ir_g = TacIrGenerator.init(alloc, &ast);
    defer ir_g.deinit();

    try ir_g.generate();

    const expected: ThreeAddressCode = .{ .op = .{ .binary_op = .add }, .arg1 = .{ .literal = .{ .number = 1 } }, .arg2 = .{ .literal = .{ .number = 2 } } };

    try std.testing.expectEqual(1, ir_g.ir_stream.items.len);
    try std.testing.expectEqual(expected, ir_g.ir_stream.items[0]);
}
