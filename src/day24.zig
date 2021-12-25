const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/puzzle/day24.txt");

const RegArg = union(enum) {
    reg: u8,
    val: i64,
};

const Alu = struct {
    reg: [4]i64 = [_]i64{ 0, 0, 0, 0 },

    fn printAlu(self: Alu) void {
        print("{: >4} {: >4} {: >12} {: >12} ", .{
            self.reg[0],
            self.reg[2],
            self.reg[1],
            self.reg[3],
        });

        var x = self.reg[3];
        while (x > 0) : (x = @divTrunc(x, 26)) {
            var k: u8 = @intCast(u8, @mod(x, 26)) + 'A';
            print("{c}", .{k});
        }
        print("\n", .{});
    }

    fn get(self: Alu, idx: u8) i64 {
        return self.reg[idx - 'w'];
    }

    fn set(self: *Alu, idx: u8, val: i64) i64 {
        self.reg[idx - 'w'] = val;
        return self.reg[idx - 'w'];
    }

    fn add(self: *Alu, idx_a: u8, b: RegArg) i64 {
        var val: i64 = undefined;
        switch (b) {
            .reg => |x| val = self.reg[x - 'w'],
            .val => |x| val = x,
        }
        self.reg[idx_a - 'w'] += val;
        return self.reg[idx_a - 'w'];
    }

    fn mul(self: *Alu, idx_a: u8, b: RegArg) i64 {
        var val: i64 = undefined;
        switch (b) {
            .reg => |x| val = self.reg[x - 'w'],
            .val => |x| val = x,
        }
        self.reg[idx_a - 'w'] *= val;
        return self.reg[idx_a - 'w'];
    }

    fn div(self: *Alu, idx_a: u8, b: RegArg) i64 {
        var val: i64 = undefined;
        switch (b) {
            .reg => |x| val = self.reg[x - 'w'],
            .val => |x| val = x,
        }
        self.reg[idx_a - 'w'] = @divTrunc(self.reg[idx_a - 'w'], val);
        return self.reg[idx_a - 'w'];
    }

    fn mod(self: *Alu, idx_a: u8, b: RegArg) i64 {
        var val: i64 = undefined;
        switch (b) {
            .reg => |x| val = self.reg[x - 'w'],
            .val => |x| val = x,
        }
        self.reg[idx_a - 'w'] = @mod(self.reg[idx_a - 'w'], val);
        return self.reg[idx_a - 'w'];
    }

    fn eql(self: *Alu, idx_a: u8, b: RegArg) i64 {
        var val: i64 = undefined;
        switch (b) {
            .reg => |x| val = self.reg[x - 'w'],
            .val => |x| val = x,
        }
        if (self.reg[idx_a - 'w'] == val) {
            self.reg[idx_a - 'w'] = 1;
        } else {
            self.reg[idx_a - 'w'] = 0;
        }
        return self.reg[idx_a - 'w'];
    }
};

pub fn main() !void {
    var lines = tokenize(data, "\r\n");
    var alu = Alu{};
    //                            0, 1, 2, 3,-3, 4,-4,-2, 5, 6,-6,-5,-1,-0
    //
    // var inputs: [14]i64 = [_]i64{ 7, 9, 9, 9, 7, 3, 9, 1, 9, 6, 9, 6, 4, 9 };
    var inputs: [14]i64 = [_]i64{ 1, 6, 9, 3, 1, 1, 7, 1, 4, 1, 4, 1, 1, 3 };
    var input_idx: u32 = 0;
    while (lines.next()) |line| {
        var parts = split(line, " ");
        var op = parts.next().?;
        var arg1: u8 = parts.next().?[0];
        if (std.mem.eql(u8, op, "inp")) {
            _ = alu.set(arg1, inputs[input_idx]);
            input_idx += 1;
            print("\n", .{});
        } else {
            var arg2: RegArg = undefined;
            var thing = parts.next().?;
            if (thing[0] >= 'w' and thing[0] <= 'z') {
                arg2 = RegArg{ .reg = thing[0] };
            } else {
                arg2 = RegArg{ .val = parseInt(i64, thing, 0) catch unreachable };
            }
            if (std.mem.eql(u8, op, "add")) {
                _ = alu.add(arg1, arg2);
            } else if (std.mem.eql(u8, op, "mul")) {
                _ = alu.mul(arg1, arg2);
            } else if (std.mem.eql(u8, op, "div")) {
                _ = alu.div(arg1, arg2);
            } else if (std.mem.eql(u8, op, "mod")) {
                _ = alu.mod(arg1, arg2);
            } else if (std.mem.eql(u8, op, "eql")) {
                _ = alu.eql(arg1, arg2);
            }
        }
        print("{s: >10} ", .{line});
        alu.printAlu();
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
