const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day01.txt");

pub fn main() !void {
    var countA: u32 = 0;
    var countB: u32 = 0;
    var prev: i32 = 9999999;
    var ringBuffer = [3]i32{ 9999999, 0, 0 };
    var bufferSum: i32 = 9999999;
    var idx: u32 = 0;

    var lines = tokenize(data, "\r\n");
    while (lines.next()) |line| {
        var x: i32 = parseInt(i32, line, 10) catch unreachable;
        if (x > prev) {
            countA += 1;
        }
        prev = x;

        if (idx > 2 and bufferSum + x - ringBuffer[idx % 3] > bufferSum) {
            countB += 1;
        }
        bufferSum -= ringBuffer[idx % 3];
        ringBuffer[idx % 3] = x;
        bufferSum += x;
        idx += 1;
    }
    print("{}\n", .{countA});
    print("{}\n", .{countB});
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
