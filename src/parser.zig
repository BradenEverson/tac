//! Core Parser and AST definition

const std = @import("std");

const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;
const TokenTag = tokenizer.TokenTag;

pub const Expr = union(enum) {
    assignment: struct { name: []const u8, val: *const Expr },
    binary_op: struct { left: *const Expr, op: BinaryOp, right: *const Expr },
    literal: Literal,
    variable: []const u8,
};

pub const Literal = union(enum) {
    number: i64,
};

pub const BinaryOp = enum {
    add,
    sub,
    mul,
    div,
};

pub const ParserError = error{
    UnexpectedToken,
};

pub const Parser = struct {
    tokens: []const Token,
    cursor: usize,
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, tokens: []const Token) Parser {
        return Parser{
            .alloc = alloc,
            .tokens = tokens,
            .cursor = 0,
        };
    }

    pub fn peek(self: *const Parser) ?Token {
        if (self.cursor + 1 < self.tokens.len) {
            return self.tokens[self.cursor];
        } else {
            return null;
        }
    }
};

test "create a parser" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    const tokens: [0]Token = .{};

    const p = Parser.init(alloc, &tokens);

    try std.testing.expectEqual(0, p.cursor);
    try std.testing.expectEqual(null, p.peek());
}
