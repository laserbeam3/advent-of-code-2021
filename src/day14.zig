const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

// const data = @embedFile("../data/test/day14.txt");
const data = @embedFile("../data/puzzle/day14.txt");

const Pair = struct {
    name: []const u8,
    idx: usize,
};

const Rule = struct {
    parent: Pair,
    left: Pair,
    right: Pair,
};

fn getPair(pairs: *StringHashMap(Pair), word: []const u8) Pair {
    if (!pairs.contains(word)) {
        var idx = pairs.count();
        var p = pairs.allocator.alloc(u8, word.len) catch unreachable;
        std.mem.copy(u8, p, word);
        pairs.put(p, .{ .name = p, .idx = idx }) catch unreachable;
    }
    return pairs.getPtr(word).?.*;
}

pub fn main() !void {
    var pairs = StringHashMap(Pair).init(gpa);
    var rules = AutoHashMap(usize, Rule).init(gpa);
    var counts = ArrayList(u64).init(gpa);
    var letter_counts: [128]u64 = std.mem.zeroes([128]u64);
    defer {
        rules.deinit();
        var it = pairs.valueIterator();
        pairs.deinit();
        counts.deinit();
    }

    var lines = tokenize(data, "\r\n");
    var startLine = lines.next().?;
    while (lines.next()) |line| {
        var words = split(line, " -> ");
        const parent = getPair(&pairs, words.next().?[0..2]);
        const dest = words.next().?[0];
        var left_buf: [2:0]u8 = "AB".*;
        left_buf[0] = parent.name[0];
        left_buf[1] = dest;
        var right_buf: [2:0]u8 = "AB".*;
        right_buf[0] = dest;
        right_buf[1] = parent.name[1];
        const left: []const u8 = &left_buf;
        const right: []const u8 = &right_buf;
        var rule = Rule{
            .parent = parent,
            .left = getPair(&pairs, left),
            .right = getPair(&pairs, right),
        };
        rules.put(parent.idx, rule) catch unreachable;
    }

    {
        var idx: usize = 0;
        while (idx < rules.count()) : (idx += 1) {
            const rule = rules.getPtr(idx).?.*;
            print("{s}({: >2}) -> {s} {s}\n", .{ rule.parent.name, rule.parent.idx, rule.left.name, rule.right.name });
            counts.append(0) catch unreachable;
        }
    }

    {
        var idx: usize = 0;
        while (idx < startLine.len - 1) : (idx += 1) {
            const p = getPair(&pairs, startLine[idx .. idx + 2]);
            counts.items[p.idx] += 1;
        }
    }

    print("{s}\n", .{startLine});
    for (counts.items) |val| {
        print("{}", .{val});
    }
    print("\n", .{});

    var max_iteration: usize = 40;
    {
        var lastPair = getPair(&pairs, startLine[startLine.len - 2 .. startLine.len]);
        var iteration: u64 = 0;
        while (iteration < max_iteration) : (iteration += 1) {
            var old: []u64 = gpa.alloc(u64, counts.items.len) catch unreachable;
            defer gpa.free(old);

            lastPair = rules.getPtr(lastPair.idx).?.right;
            std.mem.copy(u64, old, counts.items);
            std.mem.set(u64, counts.items, 0);
            for (old) |old_count, idx| {
                const rule = rules.getPtr(idx).?.*;
                counts.items[rule.left.idx] += old_count;
                counts.items[rule.right.idx] += old_count;
            }
        }

        for (counts.items) |count, idx| {
            const rule = rules.getPtr(idx).?.*;
            letter_counts[rule.parent.name[0]] += count;
        }
        letter_counts[lastPair.name[1]] += 1;
    }

    {
        var let: u8 = 'A';
        var maximum: u64 = 0;
        var minimum: u64 = 999999999999999;
        while (let <= 'Z') : (let += 1) {
            if (letter_counts[let] != 0) {
                maximum = max(maximum, letter_counts[let]);
                minimum = min(minimum, letter_counts[let]);
            }
            print("{c}: {}\n", .{ let, letter_counts[let] });
        }
        print("{} {} {}\n", .{ maximum, minimum, maximum - minimum });
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
