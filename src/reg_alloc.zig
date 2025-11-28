//! Register Allocator for an IR stream

const std = @import("std");
const builtin = @import("builtin");
const ThreeAddressCode = @import("ir.zig").ThreeAddressCode;

pub const Register = switch (builtin.cpu.arch) {
    .x86_64 => enum {
        rax,
        rbx,
        rcx,
        rdx,
        rsi,
        rdi,
        r8,
        r9,
        r10,
        r11,
        r12,
        r13,
        r14,
        r15,

        const Self = @This();
        pub fn toAsm(self: *const Self) []const u8 {
            return switch (self.*) {
                .rax => "%rax",
                .rbx => "%rbx",
                .rcx => "%rcx",
                .rdx => "%rdx",
                .rsi => "%rsi",
                .rdi => "%rdi",
                .r8 => "%r8",
                .r9 => "%r9",
                .r10 => "%r10",
                .r11 => "%r11",
                .r12 => "%r12",
                .r13 => "%r13",
                .r14 => "%r14",
                .r15 => "%r15",
            };
        }
    },

    else => @compileError("Unsupported CPU Arch"),
};

pub const RegisterAllocatedInstruction = struct {
    instr: ThreeAddressCode,
    register: ?Register,
};

pub const RegisterAllocator = struct {
    stream: []const ThreeAddressCode,
    used: [@typeInfo(Register).@"enum".fields.len]?usize,

    pub fn init(stream: []const ThreeAddressCode) RegisterAllocator {
        var self = RegisterAllocator{
            .stream = stream,
            .used = undefined,
        };

        for (0..self.used.len - 1) |i| {
            self.used[i] = null;
        }

        return self;
    }

    const InstructionWithContext = struct {
        instr: ThreeAddressCode,
        last_instr_dep: usize,
    };

    pub fn solve(self: *RegisterAllocator, output: *std.ArrayList(RegisterAllocatedInstruction), alloc: std.mem.Allocator) !void {
        var context = try alloc.alloc(InstructionWithContext, self.stream.len);
        defer alloc.free(context);

        for (0..self.stream.len) |i| {
            context[i].instr = self.stream[i];
            var last_instr_dep = i;

            for (i..self.stream.len) |j| {
                const curr = self.stream[j];
                if (self.stream[i].op == .assignment) {
                    const variable = self.stream[i].arg1.variable;
                    if (curr.arg1.dep_on_var(variable) or curr.arg2.dep_on_var(variable)) {
                        last_instr_dep = j;
                    }
                } else if (curr.arg1.dep_on(i) or curr.arg2.dep_on(i)) {
                    last_instr_dep = j;
                }
            }

            context[i].last_instr_dep = last_instr_dep;
        }

        for (0..self.stream.len) |i| {
            var chosenReg: ?Register = null;

            for (0..self.used.len) |reg| {
                if (self.used[reg]) |r| {
                    if (r <= i) {
                        self.used[reg] = context[i].last_instr_dep;
                        chosenReg = @enumFromInt(reg);
                        break;
                    }
                } else {
                    self.used[reg] = context[i].last_instr_dep;
                    chosenReg = @enumFromInt(reg);
                    break;
                }
            }

            try output.append(alloc, .{ .register = chosenReg, .instr = self.stream[i] });
        }
    }
};

test "init register allocator" {
    const ir: [0]ThreeAddressCode = .{};
    const regalloc = RegisterAllocator.init(&ir);

    try std.testing.expectEqual(14, regalloc.used.len);
    try std.testing.expectEqual(0, regalloc.stream.len);
}

test "Complex AST register allocation" {
    const TacIrGenerator = @import("ir.zig").TacIrGenerator;
    const Expr = @import("parser.zig").Expr;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const a: Expr = .{ .literal = .{ .number = 10 } };
    const b: Expr = .{ .literal = .{ .number = 9 } };

    const c: Expr = .{ .literal = .{ .number = 5 } };
    const d: Expr = .{ .literal = .{ .number = 8 } };

    const c_div_d: Expr = .{ .binary_op = .{ .op = .div, .left = &c, .right = &d } };
    const a_mul_b: Expr = .{ .binary_op = .{ .op = .mul, .left = &a, .right = &b } };

    const result: Expr = .{ .binary_op = .{ .op = .sub, .left = &a_mul_b, .right = &c_div_d } };
    const assign: Expr = .{ .assignment = .{ .name = "A", .val = &result } };

    var ast = [1]*const Expr{&assign};

    var ir_g = TacIrGenerator.init(alloc, &ast);
    defer ir_g.deinit();
    try ir_g.generate();

    const ir = ir_g.ir_stream.items;
    var regalloc = RegisterAllocator.init(ir);

    var out = std.ArrayList(RegisterAllocatedInstruction){};
    defer out.deinit(alloc);

    try regalloc.solve(&out, alloc);

    try std.testing.expectEqual(.rax, out.items[0].register);
    try std.testing.expectEqual(.rbx, out.items[1].register);
    try std.testing.expectEqual(.rax, out.items[2].register);
    try std.testing.expectEqual(.rax, out.items[3].register);
}
