const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day02.txt");

const Direction = enum {
    forward,
    down,
    up,
};

pub fn main() !void {
    var depth: i32 = 0;
    var length: i32 = 0;

    var depth2: i32 = 0;
    var length2: i32 = 0;
    var aim: i32 = 0;

    var lines = tokenize(data, "\r\n");
    while (lines.next()) |line| {
        // Part 1
        var words = split(line, " ");
        const dir_str = words.next().?;
        const dist_str = words.next().?;
        const dist = parseInt(i32, dist_str, 10) catch unreachable;
        switch (strToEnum(Direction, dir_str).?) {
            .forward => length += dist,
            .down => depth += dist,
            .up => depth -= dist,
        }

        // Part 2
        switch (strToEnum(Direction, dir_str).?) {
            .forward => {
                length2 += dist;
                depth2 += dist * aim;
            },
            .down => aim += dist,
            .up => aim -= dist,
        }
    }
    print("{} {} {}\n", .{ length, depth, length * depth });
    print("{} {} {}\n", .{ length2, depth2, length2 * depth2 });
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

const strToEnum = std.meta.stringToEnum;

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
