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
    arena: std.heap.ArenaAllocator,

    pub fn init(alloc: std.mem.Allocator, tokens: []const Token) Parser {
        return Parser{
            .arena = std.heap.ArenaAllocator.init(alloc),
            .tokens = tokens,
            .cursor = 0,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
    }

    fn peek(self: *const Parser) TokenTag {
        return self.tokens[self.cursor].tag;
    }

    fn advance(self: *Parser) void {
        if (self.cursor >= self.tokens.len - 1) {
            self.cursor = self.tokens.len - 1;
        } else {
            self.cursor += 1;
        }
    }

    fn consume(self: *Parser, tok: TokenTag) ParserError!void {
        if (std.meta.eql(self.peek().?, tok)) {
            self.advance();
            return;
        } else {
            return ParserError.UnexpectedToken;
        }
    }

    fn at_end(self: *Parser) bool {
        return self.peek() == .eof;
    }
};

test "create a parser" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    const tokens: [0]Token = .{};

    const p = Parser.init(alloc, &tokens);

    try std.testing.expectEqual(0, p.cursor);
}
