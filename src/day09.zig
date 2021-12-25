const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day09.txt");

fn fill_basin(map: [150][150]u64, basins: *[150][150]u64, ridx: u64, cidx: u64, bidx: u64, n: u64, m: u64) u64 {
    var size: u64 = 1;
    var cell = map[ridx][cidx];
    if (basins[ridx][cidx] != 0) return 0;

    basins[ridx][cidx] = bidx;
    if (ridx > 0 and map[ridx - 1][cidx] > cell and map[ridx - 1][cidx] < 9) {
        size += fill_basin(map, basins, ridx - 1, cidx, bidx, n, m);
    }
    if (ridx < n - 1 and map[ridx + 1][cidx] > cell and map[ridx + 1][cidx] < 9) {
        size += fill_basin(map, basins, ridx + 1, cidx, bidx, n, m);
    }
    if (cidx > 0 and map[ridx][cidx - 1] > cell and map[ridx][cidx - 1] < 9) {
        size += fill_basin(map, basins, ridx, cidx - 1, bidx, n, m);
    }
    if (cidx < m - 1 and map[ridx][cidx + 1] > cell and map[ridx][cidx + 1] < 9) {
        size += fill_basin(map, basins, ridx, cidx + 1, bidx, n, m);
    }
    return size;
}

pub fn main() !void {
    var map: [150][150]u64 = [_][150]u64{[_]u64{0} ** 150} ** 150;
    var basins: [150][150]u64 = [_][150]u64{[_]u64{0} ** 150} ** 150;
    var sizes = ArrayList(u64).init(gpa);
    defer sizes.deinit();
    var lines = tokenize(data, "\r\n");
    var total_sum: u64 = 0;
    var rridx: u64 = 0;
    var n: u64 = 0;
    var m: u64 = 0;
    while (lines.next()) |line| : (rridx += 1) {
        for (line) |char, cidx| {
            map[rridx][cidx] = char - '0';
            if (cidx > m) m = cidx;
        }
    }
    n = rridx;
    m += 1;

    print("{} {}\n", .{ n, m });
    var basin_idx: u64 = 1;
    for (map) |row, ridx| {
        if (ridx == n) break;
        for (row) |cell, cidx| {
            if (cidx == m) break;
            if (ridx > 0 and map[ridx - 1][cidx] <= cell) continue;
            if (ridx < n - 1 and map[ridx + 1][cidx] <= cell) continue;
            if (cidx > 0 and map[ridx][cidx - 1] <= cell) continue;
            if (cidx < m - 1 and map[ridx][cidx + 1] <= cell) continue;
            var size = fill_basin(map, &basins, ridx, cidx, basin_idx, n, m);
            basin_idx += 1;
            try sizes.append(size);

            // print("{} {} {}\n", .{ cell, ridx, cidx });
            total_sum += cell + 1;
        }
    }
    sort(u64, sizes.items, {}, comptime desc(u64));
    print("{}\n", .{total_sum});
    print("{}\n", .{sizes.items[0] * sizes.items[1] * sizes.items[2]});

    // var colors: []const u8 = "@%#*+=-:. ";
    var colors: []const u8 = " .:-=+*#%@";
    for (map) |row, ridx| {
        if (ridx == n) break;
        for (row) |cell, cidx| {
            if (cidx == m) break;
            var q = cell;
            if (basins[ridx][cidx] == 0) q = 9;
            print("{c}", .{colors[q]});
        }
        print("\n", .{});
    }
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
