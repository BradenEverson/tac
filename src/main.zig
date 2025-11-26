const std = @import("std");
const tokenizer = @import("tokenizer.zig");

pub fn main() void {
    std.debug.print("Let's make a Compiler\n", .{});
}

test {
    _ = .{ @import("tokenizer.zig"), @import("parser.zig"), @import("ir.zig"), @import("compiler.zig"), @import("assembler.zig") };
}
