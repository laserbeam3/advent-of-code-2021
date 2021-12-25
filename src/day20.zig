const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const trim = std.mem.trim;
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

const util = @import("util.zig");
const gpa = util.gpa;

const Answer = struct {
    part1: u64,
    part2: u64,
};

const Map = struct {
    width: i32 = 0,
    height: i32 = 0,
    border: u8 = 0,
    data: ArrayList(u8),

    fn init(allocator: *Allocator) Map {
        var data = ArrayList(u8).init(allocator);
        return .{ .data = data };
    }

    fn deinit(self: *Map) void {
        self.data.deinit();
    }

    fn cell(self: Map, row: i32, col: i32) u8 {
        if (row < 0 or row >= self.height) return self.border;
        if (col < 0 or col >= self.width) return self.border;
        return self.data.items[@intCast(u32, row * self.height + col)];
    }

    fn setCell(self: *Map, row: i32, col: i32, val: u8) void {
        self.data.items[@intCast(u32, row * self.height + col)] = val;
    }

    fn printMap(self: Map, bsize: i32) void {
        var idx: i32 = -bsize;
        while (idx < self.height + bsize) : (idx += 1) {
            var jdx: i32 = -bsize;
            while (jdx < self.width + bsize) : (jdx += 1) {
                var c: u8 = ' ';
                if (self.cell(idx, jdx) == 1) c = '#';
                print("{c}", .{c});
            }
            print("\n", .{});
        }
        print("\n", .{});
    }
};

fn compute(data: []const u8) Answer {
    var lines = tokenize(data, "\r\n");
    var rules_str = lines.next().?;
    var rules: [512]u8 = std.mem.zeroes([512]u8);
    for (rules_str) |c, idx| {
        if (c == '#') rules[idx] = 1;
    }

    var map = Map.init(gpa);
    defer map.deinit();

    while (lines.next()) |line| {
        var len = line.len;

        map.height += 1;
        map.width = @intCast(i32, len);

        map.data.ensureUnusedCapacity(len) catch unreachable;
        var arena = map.data.unusedCapacitySlice();
        map.data.items.len += len;
        for (line) |c, idx| {
            if (c == '#') {
                arena[idx] = 1;
            } else {
                arena[idx] = 0;
            }
        }
    }

    // map.printMap(2);

    var answer = Answer{ .part1 = 0, .part2 = 0 };
    var iteration: i32 = 0;
    {
        var max_iterations: i32 = 2;
        while (iteration < max_iterations) : (iteration += 1) {
            var new_map = Map.init(gpa);
            defer new_map.deinit();
            new_map.width = map.width + 2;
            new_map.height = map.height + 2;
            var new_len = @intCast(u32, new_map.width * new_map.height);
            new_map.data.ensureCapacity(new_len) catch unreachable;
            new_map.data.items.len = new_len;

            new_map.border = map.border;
            if (map.border == 0 and rules[0] == 1) new_map.border = 1;
            if (map.border == 1 and rules[511] == 0) new_map.border = 0;
            std.mem.set(u8, new_map.data.items, new_map.border);

            var idx: i32 = 0;
            while (idx < new_map.height) : (idx += 1) {
                var jdx: i32 = 0;
                while (jdx < new_map.width) : (jdx += 1) {
                    var mask: u9 = 0;
                    // zig fmt: off
                    mask |= @intCast(u9, map.cell(idx-2, jdx-2)) << 8;
                    mask |= @intCast(u9, map.cell(idx-2, jdx-1)) << 7;
                    mask |= @intCast(u9, map.cell(idx-2, jdx))   << 6;
                    mask |= @intCast(u9, map.cell(idx-1, jdx-2)) << 5;
                    mask |= @intCast(u9, map.cell(idx-1, jdx-1)) << 4;
                    mask |= @intCast(u9, map.cell(idx-1, jdx))   << 3;
                    mask |= @intCast(u9, map.cell(idx,   jdx-2)) << 2;
                    mask |= @intCast(u9, map.cell(idx,   jdx-1)) << 1;
                    mask |= @intCast(u9, map.cell(idx,   jdx));
                    new_map.setCell(idx, jdx, rules[mask]);
                    // zig fmt: on
                }
            }

            std.mem.swap(Map, &map, &new_map);
        }
    }

    for (map.data.items) |c| {
        answer.part1 += c;
    }

    {
        var max_iterations: i32 = 50;
        while (iteration < max_iterations) : (iteration += 1) {
            var new_map = Map.init(gpa);
            defer new_map.deinit();
            new_map.width = map.width + 2;
            new_map.height = map.height + 2;
            var new_len = @intCast(u32, new_map.width * new_map.height);
            new_map.data.ensureCapacity(new_len) catch unreachable;
            new_map.data.items.len = new_len;

            new_map.border = map.border;
            if (map.border == 0 and rules[0] == 1) new_map.border = 1;
            if (map.border == 1 and rules[511] == 0) new_map.border = 0;
            std.mem.set(u8, new_map.data.items, new_map.border);

            var idx: i32 = 0;
            while (idx < new_map.height) : (idx += 1) {
                var jdx: i32 = 0;
                while (jdx < new_map.width) : (jdx += 1) {
                    var mask: u9 = 0;
                    // zig fmt: off
                    mask |= @intCast(u9, map.cell(idx-2, jdx-2)) << 8;
                    mask |= @intCast(u9, map.cell(idx-2, jdx-1)) << 7;
                    mask |= @intCast(u9, map.cell(idx-2, jdx))   << 6;
                    mask |= @intCast(u9, map.cell(idx-1, jdx-2)) << 5;
                    mask |= @intCast(u9, map.cell(idx-1, jdx-1)) << 4;
                    mask |= @intCast(u9, map.cell(idx-1, jdx))   << 3;
                    mask |= @intCast(u9, map.cell(idx,   jdx-2)) << 2;
                    mask |= @intCast(u9, map.cell(idx,   jdx-1)) << 1;
                    mask |= @intCast(u9, map.cell(idx,   jdx));
                    new_map.setCell(idx, jdx, rules[mask]);
                    // zig fmt: on
                }
            }

            std.mem.swap(Map, &map, &new_map);
        }
    }

    for (map.data.items) |c| {
        answer.part2 += c;
    }
    return answer;
}

pub fn main() !void {
    const data = @embedFile("../data/puzzle/day20.txt");
    // const data = @embedFile("../data/test/day20.txt");
    var answer = compute(data);
    print("Part 1: {}\n", .{answer.part1});
    print("Part 2: {}\n", .{answer.part2});
}

test "sample data" {
    const data = @embedFile("../data/test/day20.txt");
    var answer = compute(data);
    try std.testing.expectEqual(answer.part1, 35);
    try std.testing.expectEqual(answer.part2, 3351);
}
