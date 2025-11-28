section .bss
section .text
global _start
_start:
.{ .instr = .{ .op = .{ .binary_op = .mul }, .arg1 = .{ .literal = .{ ... } }, .arg2 = .{ .literal = .{ ... } } }, .register = .rax }, 0
.{ .instr = .{ .op = .{ .assignment = void }, .arg1 = .{ .variable = { ... } }, .arg2 = .{ .reference = 0 } }, .register = .rbx }, 1
.{ .instr = .{ .op = .{ .binary_op = .sub }, .arg1 = .{ .literal = .{ ... } }, .arg2 = .{ .literal = .{ ... } } }, .register = .rax }, 2
.{ .instr = .{ .op = .{ .assignment = void }, .arg1 = .{ .variable = { ... } }, .arg2 = .{ .reference = 2 } }, .register = .rbx }, 3
.{ .instr = .{ .op = .{ .binary_op = .div }, .arg1 = .{ .variable = { ... } }, .arg2 = .{ .variable = { ... } } }, .register = .rax }, 4
.{ .instr = .{ .op = .{ .assignment = void }, .arg1 = .{ .variable = { ... } }, .arg2 = .{ .reference = 4 } }, .register = .rbx }, 5

mov rax, 60
mov rdi, 0
syscall
