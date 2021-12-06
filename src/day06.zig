const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day06.txt");

fn FishWorld(comptime T: type, comptime fish_life: usize) type {
    return struct {
        day: u64 = 1,
        counts: [fish_life]T = [_]T{0} ** fish_life,
        const Self = @This();

        fn advance(self: *Self) void {
            self.day += 1;

            var c0 = self.counts[0];
            var idx: usize = 0;
            while (idx < fish_life - 1) : (idx += 1) {
                self.counts[idx] = self.counts[idx + 1];
            }
            self.counts[6] += c0;
            self.counts[8] = c0;
        }

        fn totalFish(self: Self) T {
            var total: T = 0;
            for (self.counts) |count| {
                total += count;
            }
            return total;
        }
    };
}

pub fn main() !void {
    var counts: [9]u64 = [_]u64{0} ** 9;
    var world = FishWorld(u64, 9){};
    var words = tokenize(data, ",\r\n");
    while (words.next()) |line| {
        const x = parseInt(u64, line, 10) catch unreachable;
        counts[x] += 1;
        world.counts[x] += 1;
    }

    // Pass 1, let's simulate.
    // Fairly sure there's an O(1) solution as well...
    var day: u64 = 1;
    var last_day: u64 = 256;
    while (day <= last_day) : (day += 1) {
        var c0 = counts[0];
        var idx: u64 = 0;
        var total_fish: u64 = 0;
        while (idx < 8) : (idx += 1) {
            counts[idx] = counts[idx + 1];
            total_fish += counts[idx];
        }

        counts[8] = c0;
        counts[6] += c0;
        total_fish += 2 * c0;

        // Ok, I kinda want to print a bit of history, but I don't want to show eeeverything...
        if (day < 10 or day % 10 == 0 or last_day / 10 == day / 10) {
            print("{d: >3} {}\n", .{ day, total_fish });
        }
    }

    // V2. Using a struct;
    while (world.day <= last_day) {
        world.advance();
        if (world.day < 10 or world.day % 10 == 0 or last_day / 10 == world.day / 10) {
            print("{d: >3} {}\n", .{ world.day, world.totalFish() });
        }
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
