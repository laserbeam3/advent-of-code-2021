const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day08.txt");

const patterns: [10][]const u8 = [_][]const u8{
    "abcdeg", // 0
    "ab", // 1
    "acdfg", // 2
    "abcdf", // 3
    "abef", // 4
    "bcdef", // 5
    "bcdefg", // 6
    "abd", // 7
    "abcdefg", // 8
    "abcdef", // 9
};

const Flags = [8]u64;

const Digit = struct {
    const Self = @This();
    str: []u8,
    raw: []const u8,
    value: u64 = 0,
    flags: Flags = Flags{ 0, 0, 0, 0, 0, 0, 0, 0 },
    flags_set: bool = false,

    fn to_flags(self: *Self) Flags {
        if (self.flags_set) {
            return self.flags;
        }
        for (self.str) |letter| {
            self.flags[letter - 'a'] = 1;
        }
        self.flags_set = true;
        return self.flags;
    }

    fn equals(self: Self, other: []const u8) bool {
        if (self.raw.len != other.len) return false;
        return mem.eql(u8, self.raw, other);
    }
};

fn flagsToSegment(flags: Flags) u64 {
    for (flags) |flag, idx| {
        if (flag != 0) {
            return idx + 'a';
        }
    }
    return 0;
}

fn setFlagsSegment(flags: *Flags, segment: u64) void {
    flags[segment - 'a'] = 1;
}

fn unsetFlagsSegment(flags: *Flags, segment: u64) void {
    flags[segment - 'a'] = 0;
}

fn segmentToFlags(segment: u64, dest: *Flags) void {
    var idx = 0;
    while (idx < 7) : (idx += 1) {
        dest[idx] = 0;
    }
    dest[segment - 'a'] = 1;
}

fn flagsUnion(a: Flags, b: Flags, dest: *Flags) void {
    var idx: usize = 0;
    while (idx < 7) : (idx += 1) {
        dest[idx] = a[idx] | b[idx];
    }
}

fn flagsDiff(a: Flags, b: Flags, dest: *Flags) void {
    var idx: usize = 0;
    while (idx < 7) : (idx += 1) {
        dest[idx] = 0;
        if (a[idx] != 0 and b[idx] == 0) {
            dest[idx] = 1;
        }
    }
}

fn strValue(str: []const u8, digits_set: []Digit) u64 {
    for (digits_set) |digit| {
        if (digit.equals(str)) {
            return digit.value;
        }
    }
    return 0;
}

fn lenCmp(context: void, a: Digit, b: Digit) bool {
    return a.str.len < b.str.len;
}

pub fn main() !void {
    var lines = tokenize(data, "\r\n");
    var total_unique: u64 = 0;
    var total_sum: u64 = 0;
    while (lines.next()) |line| {
        var segments = split(line, "|");
        var digits_part = segments.next().?;
        var test_vals_part = segments.next().?;
        var digits_base_wods = tokenize(digits_part, " ");
        var test_vals_wods = tokenize(test_vals_part, " ");

        var digits_set = ArrayList(Digit).init(gpa);
        defer {
            for (digits_set.items) |digit| {
                gpa.free(digit.str);
                gpa.free(digit.raw);
            }
            digits_set.deinit();
        }
        try digits_set.ensureCapacity(10);

        var idx: u64 = 0;
        while (digits_base_wods.next()) |base| : (idx += 1) {
            var w = gpa.alloc(u8, base.len) catch unreachable;
            var wraw = gpa.alloc(u8, base.len) catch unreachable;
            // w and wraw freed by Digits!
            copy(u8, w, base);
            sort(u8, w, {}, comptime asc(u8));
            copy(u8, wraw, w);
            try digits_set.append(Digit{ .str = w, .raw = wraw });
        }
        sort(Digit, digits_set.items, {}, lenCmp);

        // digits order:
        // 1
        // 7
        // 4
        // 2, 3, 5
        // 0, 6, 9
        // 8

        // segment counts:
        // a = 8
        // b = 6
        // c = 8
        // d = 7
        // e = 4
        // f = 9
        // g = 7

        var segment_counts: Flags = Flags{ 0, 0, 0, 0, 0, 0, 0, 0 };
        var f: Flags = Flags{ 0, 0, 0, 0, 0, 0, 0, 0 };
        var mapping: [8]u64 = [_]u64{ 0, 0, 0, 0, 0, 0, 0, 0 };
        var mapping_inv: [128]u64 = [_]u64{0} ** 128;
        var inv: Flags = Flags{ 0, 0, 0, 0, 0, 0, 0, 0 };

        for (digits_set.items) |digit| {
            for (digit.str) |letter| {
                segment_counts[letter - 'a'] += 1;
            }
        }
        for (segment_counts) |value, jdx| {
            switch (value) {
                4 => {
                    mapping[jdx] = 'e';
                    mapping_inv[mapping[jdx]] = jdx;
                },
                6 => {
                    mapping[jdx] = 'b';
                    mapping_inv[mapping[jdx]] = jdx;
                },
                9 => {
                    mapping[jdx] = 'f';
                    mapping_inv[mapping[jdx]] = jdx;
                },
                else => mapping[jdx] = 'x',
            }
        }

        digits_set.items[0].value = 1;
        digits_set.items[1].value = 7;
        digits_set.items[2].value = 4;
        digits_set.items[9].value = 8;
        // Letter A
        flagsDiff(digits_set.items[1].to_flags(), digits_set.items[2].to_flags(), &f);
        var seg_a = flagsToSegment(f) - 'a';
        mapping[seg_a] = 'a';
        mapping_inv[seg_a] = seg_a;

        // Letter D
        flagsDiff(digits_set.items[2].to_flags(), digits_set.items[1].to_flags(), &f);
        unsetFlagsSegment(&f, mapping_inv['b'] + 'a');
        var seg_d = flagsToSegment(f) - 'a';
        mapping[seg_d] = 'd';
        mapping_inv[seg_d] = seg_d;

        // for (mapping) |value| {
        //     print("{c}\n", .{@intCast(u8, value)});
        // }

        for (segment_counts) |value, jdx| {
            if (mapping[jdx] != 'x') continue;
            switch (value) {
                7 => {
                    mapping[jdx] = 'g';
                    mapping_inv[mapping[jdx]] = jdx;
                },
                8 => {
                    mapping[jdx] = 'c';
                    mapping_inv[mapping[jdx]] = jdx;
                },
                else => mapping[jdx] = 'x',
            }
        }

        for (digits_set.items) |digit, q| {
            for (digit.str) |letter, jdx| {
                digit.str[jdx] = @intCast(u8, mapping[letter - 'a']);
            }
            sort(u8, digit.str, {}, comptime asc(u8));

            if (mem.eql(u8, digit.str, "cf")) {
                digits_set.items[q].value = 1;
            }
            if (mem.eql(u8, digit.str, "acf")) {
                digits_set.items[q].value = 7;
            }
            if (mem.eql(u8, digit.str, "bcdf")) {
                digits_set.items[q].value = 4;
            }
            if (mem.eql(u8, digit.str, "abdfg")) {
                digits_set.items[q].value = 5;
            }
            if (mem.eql(u8, digit.str, "acdfg")) {
                digits_set.items[q].value = 3;
            }
            if (mem.eql(u8, digit.str, "acdeg")) {
                digits_set.items[q].value = 2;
            }
            if (mem.eql(u8, digit.str, "abcdfg")) {
                digits_set.items[q].value = 9;
            }
            if (mem.eql(u8, digit.str, "abdefg")) {
                digits_set.items[q].value = 6;
            }
            if (mem.eql(u8, digit.str, "abcefg")) {
                digits_set.items[q].value = 0;
            }
            if (mem.eql(u8, digit.str, "abcdefg")) {
                digits_set.items[q].value = 8;
            }
        }

        var number: u64 = 0;
        while (test_vals_wods.next()) |x| {
            var w = gpa.alloc(u8, x.len) catch unreachable;
            defer gpa.free(w);
            copy(u8, w, x);
            sort(u8, w, {}, comptime asc(u8));
            for (digits_set.items) |digit| {
                if (digit.equals(w)) {
                    number = number * 10 + digit.value;
                }
            }
        }
        total_sum += number;
    }
    print("{}\n", .{total_sum});
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
const copy = std.mem.copy;
const mem = std.mem;

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
