const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day05.txt");
var map: [1000000]u8 = [_]u8{0} ** 1000000;

fn mapidx(x: u64, y: u64) u64 {
    return x * 1000 + y;
}

fn printRegion(w: u64) void {
    var idx: u64 = 0;
    while (idx < w) {
        defer idx += 1;
        var jdx: u64 = 0;
        while (jdx < w) {
            defer jdx += 1;

            print("{}", .{map[mapidx(idx, jdx)]});
        }
        print("\n", .{});
    }
}

pub fn main() !void {
    // Very lazy implementation.
    var count: u64 = 0;

    var lines = tokenize(data, "\r\n");
    while (lines.next()) |line| {
        var word = tokenize(line, ", ->");
        var x0 = parseInt(u32, word.next().?, 10) catch unreachable;
        var y0 = parseInt(u32, word.next().?, 10) catch unreachable;
        var x1 = parseInt(u32, word.next().?, 10) catch unreachable;
        var y1 = parseInt(u32, word.next().?, 10) catch unreachable;

        var ax = x0;
        var ay = y0;
        var idx: u64 = 0;
        while (ax != x1 or ay != y1) {
            idx = mapidx(ax, ay);
            map[idx] += 1;
            if (map[idx] == 2) {
                count += 1;
            }

            if (ax < x1) ax += 1;
            if (ay < y1) ay += 1;
            if (ax > x1) ax -= 1;
            if (ay > y1) ay -= 1;
        }

        idx = mapidx(x1, y1);
        map[idx] += 1;
        if (map[idx] == 2) {
            count += 1;
        }
    }

    printRegion(10);
    print("{}\n", .{ count });
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
