//! Tokenizing utilities for a u8 stream

const std = @import("std");

const TokenizeError = error{
    UnexpectedEOF,
};

pub const TokenTag = enum {
    ident,
    plus,
    minus,
};

pub const Token = struct {
    tag: TokenTag,
    line: usize,
    col: usize,
    data: []const u8,
};

pub fn tokenize(stream: []const u8, tokens: *std.ArrayList(Token), alloc: std.mem.Allocator) !void {
    _ = stream;
    _ = tokens;
    _ = alloc;
}

test "basic tokenize" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var tokens = std.ArrayList(Token){};

    const simple = "b = 10;";

    try tokenize(simple, &tokens, alloc);
}
