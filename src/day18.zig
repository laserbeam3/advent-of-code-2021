const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/test/day18.txt");

const SfNumber = struct {
    const Self = @This();
    const Side = enum {
        left,
        right,
    };

    depth: u64 = 0,
    value: ?u64 = null,
    left: ?*Self = null,
    right: ?*Self = null,
    parent: ?*Self = null,
    side: ?Side = null,
    allocator: *Allocator,

    fn valSplit(self: *Self, val: SfValue) SfValue {
        switch (val) {
            .sf => |sf_number| return val,
            .value => |value| {
                if (value < 10) return val;
                var a = value / 2;
                var b = value / 2 + value % 2;
                var sf = Self.init(a, b, self.allocator);
                sf.parent = self;
                return .{ .sf = sf };
            },
        }
    }

    fn init(allocator: *Allocator) *Self {
        var sf_area = allocator.alloc(Self, 1) catch unreachable;
        var sf = &sf_area[0];
        sf.* = .{ .allocator = allocator };
        return sf;
    }

    fn initPair(left_val: u64, right_val: u64, allocator: *Allocator) *Self {
        var sf = Self.init(allocator);
        var left = Self.init(allocator);
        var right = Self.init(allocator);
        sf.*.left = left;
        sf.*.right = right;

        left.*.value = left_val;
        right.*.value = right_val;
        left.*.side = .left;
        right.*.side = .right;
        left.*.parent = sf;
        right.*.parent = sf;
        left.*.depth = 1;
        right.*.depth = 1;
        return sf;
    }

    fn assignChild(self: *Self, child: *Self, side: Side) void {
        switch (side) {
            .left => {
                if (self.left) |old_child| old_child.deinit();
                self.left = child;
            },
            .right => {
                if (self.right) |old_child| old_child.deinit();
                self.right = child;
            },
        }
        child.side = side;
        child.parent = self;
        _ = child.updateDepth();
    }

    fn deinit(self: *Self) void {
        if (self.left) |child| child.deinit();
        if (self.right) |child| child.deinit();
        self.allocator.free(@ptrCast(comptime *[1]Self, self));
    }

    fn updateDepth(self: *Self) u64 {
        var d = self.depth;
        if (self.parent) |parent| {
            self.depth = parent.depth + 1;
        } else {
            self.depth = 0;
        }
        var max_depth = self.depth;

        if (d != self.depth) {
            if (self.left) |child| max_depth = max(max_depth, child.updateDepth());
            if (self.right) |child| max_depth = max(max_depth, child.updateDepth());
        }
        return max_depth;
    }

    fn splitNode(self: *Self) *Self {
        var a = self.value.? / 2;
        var b = self.value.? / 2 + self.value.? % 2;
        return Self.initPair(a, b, self.allocator);
    }

    fn doSplit(self: *Self) bool {
        if (self.left) |child| {
            if (child.value) |value| {
                if (value >= 10) {
                    self.assignChild(child.splitNode(), .left);
                    return true;
                }
            } else {
                if (child.doSplit()) return true;
            }
        }
        if (self.right) |child| {
            if (child.value) |value| {
                if (value >= 10) {
                    self.assignChild(child.splitNode(), .right);
                    return true;
                }
            } else {
                if (child.doSplit()) return true;
            }
        }
        return false;
    }

    fn magnitude(self: *Self) u64 {
        if (self.value) |value| return value;
        return 3 * self.left.?.magnitude() + 2 * self.right.?.magnitude();
    }

    fn doExplode(self: *Self) bool {
        if (self.depth >= 4 and self.value == null and self.left.?.value != null and self.right.?.value != null) {
            var p = self.parent.?;
            var left = self.left.?;
            var right = self.right.?;
            var a = left.value.?;
            var b = right.value.?;
            var side = self.side.?;

            while (right.side != null and right.side.? == .right) {
                right = right.parent.?;
            }
            if (right.parent != null) {
                right = right.parent.?;
                if (right.right.?.value != null) {
                    right.right.?.value.? += b;
                } else {
                    right = right.right.?;
                    while (right.left.?.value == null) {
                        right = right.left.?;
                    }
                    right.left.?.value.? += b;
                }
            }

            while (left.side != null and left.side.? == .left) {
                left = left.parent.?;
            }
            if (left.parent != null) {
                left = left.parent.?;
                if (left.left.?.value != null) {
                    left.left.?.value.? += a;
                } else {
                    left = left.left.?;
                    while (left.right.?.value == null) {
                        left = left.right.?;
                    }
                    left.right.?.value.? += a;
                }
            }

            var child = Self.init(self.allocator);
            child.value = 0;
            p.assignChild(child, side);

            return true;
        }

        if (self.left != null and self.left.?.doExplode()) return true;
        if (self.left != null and self.right.?.doExplode()) return true;
        return false;
    }

    fn simplfy(self: *Self) void {
        var did_something: bool = true;
        while (did_something) {
            did_something = self.doExplode();
            if (!did_something) {
                did_something = self.doSplit();
            }
        }
    }

    fn parseFromString(str: []const u8, allocator: *Allocator) !*Self {
        var depth: u64 = 0;
        const SfParsedType = enum {
            num,
            pair,
        };
        const SfParsed = union(SfParsedType) {
            num: u64,
            pair: *Self,
        };

        var num_stack = ArrayList(SfParsed).init(gpa);
        defer num_stack.deinit();

        var idx: usize = 0;
        while (idx < str.len) : (idx += 1) {
            var char = str[idx];
            switch (char) {
                '0'...'9' => {
                    var part = tokenize(str[idx..], "[],").next().?;
                    var value = parseInt(u64, part, 0) catch unreachable;
                    num_stack.append(.{ .num = value }) catch unreachable;
                    idx += part.len - 1;
                },
                ']' => {
                    var vright = num_stack.pop();
                    var vleft = num_stack.pop();
                    var sf = Self.init(allocator);
                    switch (vleft) {
                        .num => |num| {
                            var child = Self.init(allocator);
                            child.*.value = num;
                            sf.assignChild(child, .left);
                        },
                        .pair => |pair| sf.assignChild(pair, .left),
                    }
                    switch (vright) {
                        .num => |num| {
                            var child = Self.init(allocator);
                            child.*.value = num;
                            sf.assignChild(child, .right);
                        },
                        .pair => |pair| sf.assignChild(pair, .right),
                    }
                    num_stack.append(.{ .pair = sf }) catch unreachable;
                },
                else => {},
            }
        }

        var x = num_stack.pop();
        switch (x) {
            .num => return error.InvalidNumber,
            .pair => |value| return value,
        }
    }

    fn printShort(self: *Self) void {
        if (self.value) |value| {
            print("{}", .{value});
        } else {
            print("[", .{});
            if (self.left) |child| child.printShort();
            print(",", .{});
            if (self.right) |child| child.printShort();
            print("]", .{});
        }
    }

    fn printTree(self: *Self, depth: usize) void {
        var idx: usize = 0;
        while (idx < depth) : (idx += 1) {
            print(" ", .{});
        }

        if (self.value) |value| {
            print("{} {}\n", .{ self.side, value });
        } else {
            print("{} [\n", .{self.side});
        }

        if (self.left) |child| child.printTree(depth + 2);
        if (self.right) |child| child.printTree(depth + 2);
    }
};

pub fn main() !void {
    var lines = tokenize(data, "\r\n");
    var all_lines = ArrayList([]const u8).init(gpa);
    defer all_lines.deinit();
    var line0 = lines.next().?;
    all_lines.append(line0) catch unreachable;
    var sf_number = SfNumber.parseFromString(line0, gpa) catch unreachable;
    defer sf_number.deinit();

    while (lines.next()) |line| {
        all_lines.append(line) catch unreachable;
        var old_number = sf_number;
        var new_number = SfNumber.parseFromString(line, gpa) catch unreachable;
        sf_number = SfNumber.init(gpa);
        sf_number.assignChild(old_number, .left);
        sf_number.assignChild(new_number, .right);
        sf_number.simplfy();
    }
    sf_number.printShort();
    print(" {} \n", .{sf_number.magnitude()});

    var maximum: u64 = 0;
    {
        var idx: usize = 0;
        while (idx < all_lines.items.len) : (idx += 1) {
            var jdx: usize = idx + 1;
            while (jdx < all_lines.items.len) : (jdx += 1) {
                {
                    var a = SfNumber.parseFromString(all_lines.items[idx], gpa) catch unreachable;
                    var b = SfNumber.parseFromString(all_lines.items[jdx], gpa) catch unreachable;
                    var x = SfNumber.init(gpa);
                    defer x.deinit();
                    x.assignChild(a, .left);
                    x.assignChild(b, .right);
                    x.simplfy();
                    maximum = max(x.magnitude(), maximum);
                }

                {
                    var a = SfNumber.parseFromString(all_lines.items[idx], gpa) catch unreachable;
                    var b = SfNumber.parseFromString(all_lines.items[jdx], gpa) catch unreachable;
                    var x = SfNumber.init(gpa);
                    defer x.deinit();
                    x.assignChild(b, .left);
                    x.assignChild(a, .right);
                    x.simplfy();
                    maximum = max(x.magnitude(), maximum);
                }
            }
        }
    }
    print(" {} \n", .{maximum});
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
