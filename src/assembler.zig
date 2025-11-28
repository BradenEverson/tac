//! Translation between TAC IR and x86-64 Assembly

const std = @import("std");

const Instruction = @import("reg_alloc.zig").RegisterAllocatedInstruction;

pub const Assembler = struct {
    ir: []Instruction,
    fd: std.fs.File,

    pub fn init(name: []const u8, codes: []Instruction) !Assembler {
        const fd = try std.fs.cwd().createFile(name, .{});
        return Assembler{ .ir = codes, .fd = fd };
    }

    pub fn deinit(self: *Assembler) void {
        self.fd.close();
    }

    pub fn translate(self: *Assembler, alloc: std.mem.Allocator) !void {
        _ = try self.fd.write(
            \\section .bss
            \\section .text
            \\global _start
            \\_start:
            \\
        );

        for (self.ir, 0..) |tac, i| {
            const instr = try std.fmt.allocPrint(alloc, "{any}, {d}\n", .{ tac, i });
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
