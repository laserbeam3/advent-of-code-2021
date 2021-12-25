const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;
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

const data = @embedFile("../data/puzzle/day25.txt");
// const data = @embedFile("../data/test/day25.txt");

const Map = struct {
    data: ArrayList(u8),
    width: usize = 0,
    height: usize = 0,
    temp_allocator: *Allocator,

    fn init(allocator: *Allocator, temp_allocator: *Allocator) Map {
        return .{
            .data = ArrayList(u8).init(allocator),
            .temp_allocator = temp_allocator,
        };
    }

    fn readLine(self: *Map, str: []const u8) void {
        self.height += 1;
        self.width = str.len;

        self.data.ensureUnusedCapacity(str.len) catch unreachable;
        var arena = self.data.unusedCapacitySlice();
        self.data.items.len += str.len;
        std.mem.copy(u8, arena, str);
    }

    fn deinit(self: *Map) void {
        self.data.deinit();
    }

    fn printMap(self: *Map) void {
        var row_idx: usize = 0;
        while (row_idx < self.height) : (row_idx += 1) {
            var r1 = row_idx * self.width;
            var r2 = (row_idx + 1) * self.width;
            print("{s}\n", .{self.data.items[r1..r2]});
        }
        print("\n", .{});
    }

    fn advance(self: *Map) bool {
        var new_state = self.temp_allocator.alloc(u8, self.data.items.len) catch unreachable;
        defer self.temp_allocator.free(new_state);
        std.mem.copy(u8, new_state, self.data.items);

        var moved = false;
        for (self.data.items) |cell, idx| {
            if (cell == '>') {
                var x = idx / self.width;
                var y = idx % self.width;
                var new_y = (y + 1) % self.width;
                var new_idx = x * self.width + new_y;
                if (self.data.items[new_idx] == '.') {
                    new_state[idx] = '.';
                    new_state[new_idx] = '>';
                    moved = true;
                }
            }
        }
        if (moved) {
            std.mem.copy(u8, self.data.items, new_state);
        }
        for (self.data.items) |cell, idx| {
            if (cell == 'v') {
                var x = idx / self.width;
                var y = idx % self.width;
                var new_x = (x + 1) % self.height;
                var new_idx = new_x * self.width + y;
                if (self.data.items[new_idx] == '.') {
                    new_state[idx] = '.';
                    new_state[new_idx] = 'v';
                    moved = true;
                }
            }
        }
        if (moved) {
            std.mem.copy(u8, self.data.items, new_state);
        }
        return moved;
    }
};

pub fn main() !void {
    var map = Map.init(gpa, gpa);
    defer map.deinit();
    var lines = tokenize(data, "\n\r");
    while (lines.next()) |line| {
        map.readLine(line);
    }

    map.printMap();

    var iterations: u64 = 1;
    while (map.advance()) {
        iterations += 1;
    }
    map.printMap();
    print("{}\n", .{iterations});
}
