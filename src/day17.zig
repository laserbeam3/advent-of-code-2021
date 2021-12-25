const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day17.txt");

pub fn main() !void {
    var parts = split(data, "x=");
    var line = parts.next().?;
    line = parts.next().?;
    var values = tokenize(line, "., y=\r\n");
    var x0: i64 = parseInt(i64, values.next().?, 10) catch unreachable;
    var x1: i64 = parseInt(i64, values.next().?, 10) catch unreachable;
    var y0: i64 = parseInt(i64, values.next().?, 10) catch unreachable;
    var y1: i64 = parseInt(i64, values.next().?, 10) catch unreachable;
    print("{} {} {} {}\n", .{ x0, x1, y0, y1 });

    var count: i64 = 0;
    var vx: i64 = 0;
    while (vx <= x1) : (vx += 1) {
        var vy: i64 = -y0;
        while (vy >= y0) : (vy -= 1) {
            var x = vx;
            var dx = vx;
            var y = vy;
            var dy = vy;
            while (x <= x1 and y >= y0) {
                if (x0 <= x and x <= x1 and y0 <= y and y <= y1) {
                    count += 1;
                    break;
                }
                dx = max(0, dx-1);
                dy -= 1;
                x += dx;
                y += dy;
            }
        }
    }
    print("{}", .{count});
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
