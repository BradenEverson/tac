//! Translation between TAC IR and x86-64 Assembly

const std = @import("std");

const ir = @import("ir.zig");
const ThreeAddressCode = ir.ThreeAddressCode;

pub const Assembler = struct {
    ir: []ThreeAddressCode,
    fd: std.fs.File,

    pub fn init(name: []const u8, codes: []ThreeAddressCode) !Assembler {
        const fd = try std.fs.cwd().createFile(name, .{});
        return Assembler{ .ir = codes, .fd = fd };
    }

    pub fn deinit(self: *Assembler) void {
        self.fd.close();
    }

    pub fn translate(self: *Assembler, alloc: std.mem.Allocator) !void {
        _ = alloc;
        try self.fd.write(
            \\section .bss
            \\section .text
            \\global _start
            \\_start:
            \\
        );

        for (self.ir, 0..) |tac, i| {
            _ = tac;
            _ = i;
        }
    }
};
