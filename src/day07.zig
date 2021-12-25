const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day07.txt");

pub fn main() !void {
    var crabs = ArrayList(i64).init(gpa);
    defer crabs.deinit();
    var words = tokenize(data, ",\r\n");
    while (words.next()) |line| {
        const x = parseInt(i64, line, 10) catch unreachable;
        try crabs.append(x);
    }
    sort(i64, crabs.items, {}, comptime asc(i64));

    var val: i64 = crabs.items[0];
    var min_total: i64 = 9999999999;
    const n = crabs.items[crabs.items.len - 1];
    while (val <= n) : (val += 1) {
        var total: i64 = 0;
        for (crabs.items) |crab| {
            var x: i64 = abs(crab - val) catch unreachable;
            total += @divFloor(x * (x+1), 2);
        }
        if (total < min_total) {
            min_total = total;
        }
    }
    // for (crabs.items) |crab| {
    //     print("{}\n", .{crab});
    // }
    print("{}\n", .{min_total});
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

const abs = std.math.absInt;
const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
