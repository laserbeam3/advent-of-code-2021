const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const PriorityQueue = std.PriorityQueue;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

// const data = @embedFile("../data/test/day15.txt");
const data = @embedFile("../data/puzzle/day15.txt");

const Coord = struct {
    const Self = @This();
    x: usize,
    y: usize,
    risk: u64,

    fn cmp(a: Self, b: Self) std.math.Order {
        return std.math.order(a.risk, b.risk);
    }
};

fn cycle(a: u64, b: u64) u64 {
    return (a + b - 1) % 9 + 1;
}

pub fn main() !void {
    var map = std.mem.zeroes([500][500]u64);
    var risk: [500][500]u64 = undefined;
    var queue = PriorityQueue(Coord).init(gpa, Coord.cmp);
    defer queue.deinit();

    var lines = tokenize(data, "\n\r");
    var idx: usize = 0;
    var n: usize = 0;
    var m: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        m = line.len;
        n = max(idx + 1, n);
    }
    print("{} {}\n", .{ n, m });

    idx = 0;
    lines = tokenize(data, "\n\r");
    while (lines.next()) |line| : (idx += 1) {
        for (line) |cell, jdx| {
            map[idx][jdx] = cell - '0';
            risk[idx][jdx] = 9999999999999;

            var offx: usize = 0;
            while (offx < 5) : (offx += 1) {
                var offy: usize = 0;
                while (offy < 5) : (offy += 1) {
                    var tile = offx + offy;
                    if (offx == 0 and offy == 0) continue;
                    var ax = idx + n * offx;
                    var ay = jdx + m * offy;
                    map[ax][ay] = cycle(map[idx][jdx], tile);
                    risk[ax][ay] = 9999999999999;
                }
            }
            // break :outer;
        }
    }

    print("Made map!\n", .{});

    try queue.add(.{ .x = 0, .y = 0, .risk = 0 });
    var nn = n * 5;
    var mm = m * 5;
    while (risk[n * 5 - 1][m * 5 - 1] == 9999999999999) {
        var next = queue.remove();
        if (risk[next.x][next.y] != 9999999999999) continue;
        risk[next.x][next.y] = next.risk;
        if (next.x > 0 and risk[next.x - 1][next.y] > next.risk + map[next.x - 1][next.y]) {
            try queue.add(.{ .x = next.x - 1, .y = next.y, .risk = next.risk + map[next.x - 1][next.y] });
        }
        if (next.x < nn - 1 and risk[next.x + 1][next.y] > next.risk + map[next.x + 1][next.y]) {
            try queue.add(.{ .x = next.x + 1, .y = next.y, .risk = next.risk + map[next.x + 1][next.y] });
        }
        if (next.y > 0 and risk[next.x][next.y - 1] > next.risk + map[next.x][next.y - 1]) {
            try queue.add(.{ .x = next.x, .y = next.y - 1, .risk = next.risk + map[next.x][next.y - 1] });
        }
        if (next.y < mm - 1 and risk[next.x][next.y + 1] > next.risk + map[next.x][next.y + 1]) {
            try queue.add(.{ .x = next.x, .y = next.y + 1, .risk = next.risk + map[next.x][next.y + 1] });
        }
    }

    print("{}\n", .{risk[n - 1][m - 1]});
    print("{}\n", .{risk[n * 5 - 1][m * 5 - 1]});
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
