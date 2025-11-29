//! Main assembler program that:
//! - loads a provided file
//! - tokenizes it
//! - parses the tokens
//! - Creates a stream of Three Address Codes
//! - Allocates registers for these instructions
//! - Translates the final stream to valid NASM x86-64 asm

const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;

const parser = @import("parser.zig");
const Expr = parser.Expr;
const Parser = parser.Parser;

const ir = @import("ir.zig");
const TacIrGenerator = ir.TacIrGenerator;
const ThreeAddressCode = ir.ThreeAddressCode;

const reg_alloc = @import("reg_alloc.zig");
const RegisterAllocator = reg_alloc.RegisterAllocator;
const RegisterAllocatedInstruction = reg_alloc.RegisterAllocatedInstruction;

const Assembler = @import("assembler.zig").Assembler;

pub fn main() void {
    const alloc = std.heap.page_allocator;

    var args = std.process.args();
    _ = args.next(); // process name

    if (args.next()) |path| {
        const data = std.fs.cwd().readFileAlloc(alloc, path, std.math.maxInt(usize)) catch @panic("Failed to open file\n");
        defer alloc.free(data);

        var tokens = std.ArrayList(Token){};
        defer tokens.deinit(alloc);

        tokenizer.tokenize(data, &tokens, alloc) catch @panic("Failed to tokenize stream");

        var parse = Parser.init(alloc, tokens.items);
        defer parse.deinit();

        var ast = std.ArrayList(*const Expr){};

        parse.parse(&ast) catch @panic("Failed to parse tokens :(");

        var ir_generator = TacIrGenerator.init(alloc, ast.items);
        defer ir_generator.deinit();

        ir_generator.generate() catch @panic("Failed to generate IR");

        const tac = ir_generator.ir_stream.items;

        var register_allocator = RegisterAllocator.init(tac);

        var instructions = std.ArrayList(RegisterAllocatedInstruction){};
        register_allocator.solve(&instructions, alloc) catch @panic("Failed to allocate registers");

        var assembler = Assembler.init("generated.S", instructions.items) catch @panic("Failed to create assembly file");
        defer assembler.deinit(alloc);

        assembler.translate(alloc) catch @panic("Failed to generate assembly");
    } else {
        std.debug.print("Usage: ./tac {{file}}\n", .{});
    }
}

test {
    _ = .{ @import("tokenizer.zig"), @import("parser.zig"), @import("ir.zig"), @import("compiler.zig"), @import("assembler.zig"), @import("reg_alloc.zig") };
}
