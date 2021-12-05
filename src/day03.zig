const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day03.txt");

fn sortByMaskFn(comptime mask: u64) fn ([]u64) u64 {
    const impl = struct {
        fn cmp(context: void, a: u64, b: u64) bool {
            if (a & mask != 0 and b & mask == 0) {
                return false;
            } else {
                return true;
            }
        }

        fn inner(items: []u64) u64 {
            // TODO(catalin): This sort can be done in one pass, and doesn't need comparisons.
            sort(u64, items, {}, cmp);
            var zeroes: u64 = 0;
            while (zeroes < items.len and items[zeroes] & mask == 0) {
                zeroes += 1;
            }
            return zeroes;
        }
    };
    return impl.inner;
}

// I'm sure these 2 are already defined somewhere...
fn cmpGt(a: u64, b: u64) bool {
    return a > b;
}

fn cmpLe(a: u64, b: u64) bool {
    return a <= b;
}

// zig fmt: off
const maskSorts = [_]fn ([]u64) u64{
    sortByMaskFn(1 << 0), sortByMaskFn(1 << 1), sortByMaskFn(1 << 2), sortByMaskFn(1 << 3),
    sortByMaskFn(1 << 4), sortByMaskFn(1 << 5), sortByMaskFn(1 << 6), sortByMaskFn(1 << 7),
    sortByMaskFn(1 << 8), sortByMaskFn(1 << 9), sortByMaskFn(1 << 10), sortByMaskFn(1 << 11) };
// zig fmt: on

fn getPart2Result(items: []u64, bitCount: u64, cmpRule: fn (u64, u64) bool) u64 {
    var maskIdx: u64 = bitCount - 1;
    var first: u64 = 0;
    var last: u64 = items.len;
    var size: u64 = last - first;
    var zeroes: u64 = 0;
    while (size > 1) {
        zeroes = maskSorts[maskIdx](items[first..last]);
        if (cmpRule(zeroes * 2, size)) {
            last = first + zeroes;
        } else {
            first += zeroes;
        }
        size = last - first;
        if (maskIdx == 0) {
            break;
        }
        maskIdx -= 1;
    }
    return items[first];
}

pub fn main() !void {
    // Part 1
    const first_line: []const u8 = tokenize(data, "\r\n").next().?;
    const bitCount: u64 = first_line.len;
    var itemCount: u64 = 0;
    var onesCount: [12]u64 = std.mem.zeroes([12]u64);
    var inputs = ArrayList(u64).init(gpa);
    defer inputs.deinit();

    var lines = tokenize(data, "\r\n");
    while (lines.next()) |line| {
        const x = parseInt(u64, line, 2) catch unreachable;
        try inputs.append(x);
        var mask: u64 = 1;
        var idx: u64 = 0;
        while (idx < bitCount) {
            if (x & mask != 0) {
                onesCount[idx] += 1;
            }
            mask <<= 1;
            idx += 1;
        }
        itemCount += 1;
    }

    var mask: u64 = 1;
    var gamma: u64 = 0;
    var epsilon: u64 = 0;
    for (onesCount[0..bitCount]) |count| {
        if (count * 2 > itemCount) {
            gamma |= mask;
        } else {
            epsilon |= mask;
        }
        mask <<= 1;
    }
    print("{} {} {}\n", .{ gamma, epsilon, gamma * epsilon });

    // Part 2
    const oxygen = getPart2Result(inputs.items, bitCount, cmpGt);
    const co2 = getPart2Result(inputs.items, bitCount, cmpLe);
    print("{b:0>12} {b:0>12} {}\n", .{ oxygen, co2, oxygen * co2 });
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
