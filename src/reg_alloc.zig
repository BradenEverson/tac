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
    },

    else => @compileError("Unsupported CPU Arch"),
};

pub const RegisterAllocatedInstruction = struct {
    instr: ThreeAddressCode,
    register: ?Register,
};

pub const RegisterAllocator = struct {
    stream: []const ThreeAddressCode,
    used: [@typeInfo(Register).@"enum".fields.len]?*ThreeAddressCode,

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

    pub fn solve(self: *RegisterAllocator, output: std.ArrayList(RegisterAllocatedInstruction), alloc: std.mem.Allocator) !void {
        _ = self;
        _ = output;
        _ = alloc;
    }
};

test "init register allocator" {
    const ir: [0]ThreeAddressCode = .{};
    const regalloc = RegisterAllocator.init(&ir);

    try std.testing.expectEqual(14, regalloc.used.len);
    try std.testing.expectEqual(0, regalloc.stream.len);
}
