const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day10.txt");

pub fn main() !void {
    var lines = tokenize(data, "\r\n");
    var score: u64 = 0;
    var completion = ArrayList(u64).init(gpa);
    defer completion.deinit();
    while (lines.next()) |line| {
        var stack = ArrayList(u8).init(gpa);
        defer stack.deinit();
        loop: for (line) |char| {
            switch (char) {
                '(', '[', '{', '<' => try stack.append(char),
                ')', ']', '}', '>' => {
                    var x = stack.pop();
                    if (char == ')' and x != '(') {
                        score += 3;
                        break :loop;
                    }
                    if (char == ']' and x != '[') {
                        score += 57;
                        break :loop;
                    }
                    if (char == '}' and x != '{') {
                        score += 1197;
                        break :loop;
                    }
                    if (char == '>' and x != '<') {
                        score += 25137;
                        break :loop;
                    }
                },
                else => {},
            }
        } else {
            var s: u64 = 0;
            while (stack.popOrNull()) |x| {
                s *= 5;
                switch (x) {
                    '(' => s += 1,
                    '[' => s += 2,
                    '{' => s += 3,
                    '<' => s += 4,
                    else => {},
                }
            }
            try completion.append(s);
        }
    }
    sort(u64, completion.items, {}, comptime asc(u64));
    print("{}\n", .{score});
    print("{}\n", .{completion.items[completion.items.len / 2]});
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
