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

pub fn main() !void {}
