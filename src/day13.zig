const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day13.txt");

const Dot = struct {
    x: i64,
    y: i64,
};

const Axis = enum {
    x,
    y,
};

fn foldDots(dots: *AutoHashMap(Dot, bool), coord: i64, axis: Axis) void {
    var to_swap = ArrayList(Dot).init(gpa);
    defer to_swap.deinit();

    var it = dots.keyIterator();
    while (it.next()) |key_ptr| {
        if (key_ptr.x > coord and axis == Axis.x) {
            to_swap.append(key_ptr.*) catch unreachable;
        } else if (key_ptr.y > coord and axis == Axis.y) {
            to_swap.append(key_ptr.*) catch unreachable;
        }
    }

    for (to_swap.items) |dot| {
        var thing = dots.remove(dot);
        if (axis == Axis.x) {
            var aux = dots.getOrPutValue(.{ .x = 2 * coord - dot.x, .y = dot.y }, true) catch unreachable;
        } else {
            var aux = dots.getOrPutValue(.{ .x = dot.x, .y = 2 * coord - dot.y }, true) catch unreachable;
        }
    }
}

pub fn main() !void {
    var dots = AutoHashMap(Dot, bool).init(gpa);
    defer dots.deinit();

    var lines = tokenize(data, "\r\n");
    while (lines.next()) |line| {
        if (line[0] == 'f') {
            var words = split(line, "=");
            var axis = strToEnum(Axis, words.next().?[11..12]).?;
            var val = parseInt(i64, words.next().?, 10) catch unreachable;
            foldDots(&dots, val, axis);
            print("Folded {}={}: {}\n", .{ axis, val, dots.count() });
        } else {
            var words = split(line, ",");
            var x = parseInt(i64, words.next().?, 10) catch unreachable;
            var y = parseInt(i64, words.next().?, 10) catch unreachable;
            var aux = dots.getOrPutValue(.{ .x = x, .y = y }, true) catch unreachable;
        }
    }

    var map = std.mem.zeroes([6][60]u8);
    var it = dots.keyIterator();
    while (it.next()) |key_ptr| {
        map[@intCast(usize, key_ptr.y)][@intCast(usize, key_ptr.x)] = 1;
    }
    print("\n", .{});
    for (map) |row| {
        for (row) |cell| {
            if (cell == 1) print("X", .{});
            if (cell == 0) print(" ", .{});
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
