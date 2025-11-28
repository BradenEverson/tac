section .bss
section .text
global _start
_start:

mov rax, 10
imul rax, 9
mov rbx, 7
sub rbx, 1
add rax, rbx

mov rax, 60
mov rdi, 0
syscall
