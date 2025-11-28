//! Translation between TAC IR and x86-64 Assembly

const std = @import("std");

const reg_alloc = @import("reg_alloc.zig");
const Instruction = reg_alloc.RegisterAllocatedInstruction;
const Register = reg_alloc.Register;
const Operand = @import("ir.zig").Operand;

pub const Assembler = struct {
    ir: []Instruction,
    fd: std.fs.File,
    mappings: std.StringHashMapUnmanaged(Register),

    pub fn init(name: []const u8, codes: []Instruction) !Assembler {
        const fd = try std.fs.cwd().createFile(name, .{});
        return Assembler{ .ir = codes, .fd = fd, .mappings = std.StringHashMapUnmanaged(Register){} };
    }

    pub fn deinit(self: *Assembler, alloc: std.mem.Allocator) void {
        self.fd.close();
        self.mappings.deinit(alloc);
    }

    pub fn operandToAsm(self: *Assembler, operand: Operand, alloc: std.mem.Allocator) ![]const u8 {
        switch (operand) {
            .literal => |l| return l.toAsm(alloc),
            .reference => |r| return self.ir[r].register.?.toAsm(),
            .variable => |v| return self.mappings.get(v).?.toAsm(),
        }
    }

    pub fn translateSingle(self: *Assembler, instr: Instruction, alloc: std.mem.Allocator) ![]const u8 {
        switch (instr.instr.op) {
            .binary_op => |b| {
                const op = b.toAsm();
                const left = try self.operandToAsm(instr.instr.arg1, alloc);
                const right = try self.operandToAsm(instr.instr.arg2, alloc);
                const reg = instr.register.?.toAsm();

                if (std.mem.eql(u8, reg, left)) {
                    return std.fmt.allocPrint(alloc, "{s} {s}, {s}\n", .{ op, reg, right });
                } else {
                    return std.fmt.allocPrint(alloc, "mov {s}, {s}\n{s} {s}, {s}\n", .{ reg, left, op, reg, right });
                }
            },

            .assignment => {
                const reg = instr.register.?.toAsm();
                const value = try self.operandToAsm(instr.instr.arg2, alloc);

                const varname = instr.instr.arg1.variable;
                try self.mappings.put(alloc, varname, instr.register.?);

                if (!std.mem.eql(u8, reg, value)) {
                    return std.fmt.allocPrint(alloc, "mov {s}, {s}\n", .{ reg, value });
                } else {
                    return "";
                }
            },
        }
    }

    pub fn translate(self: *Assembler, alloc: std.mem.Allocator) !void {
        _ = try self.fd.write(
            \\section .bss
            \\section .text
            \\global _start
            \\_start:
            \\
            \\
        );

        for (self.ir) |tac| {
            const instr = try self.translateSingle(tac, alloc);
            _ = try self.fd.write(instr);
        }

        _ = try self.fd.write(
            \\
            \\mov rax, 60
            \\mov rdi, 0
            \\syscall
            \\
        );
    }
};
