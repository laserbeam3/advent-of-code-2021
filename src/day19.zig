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

const Rotation = [3][3]i32;
const rotations: [24]Rotation = [24]Rotation{
    // X+
    Rotation{ [3]i32{ 1, 0, 0 }, [3]i32{ 0, 1, 0 }, [3]i32{ 0, 0, 1 } }, // 0
    Rotation{ [3]i32{ 1, 0, 0 }, [3]i32{ 0, 0, -1 }, [3]i32{ 0, 1, 0 } }, // 1
    Rotation{ [3]i32{ 1, 0, 0 }, [3]i32{ 0, -1, 0 }, [3]i32{ 0, 0, -1 } }, // 2
    Rotation{ [3]i32{ 1, 0, 0 }, [3]i32{ 0, 0, 1 }, [3]i32{ 0, -1, 0 } }, // 3

    // X-
    Rotation{ [3]i32{ -1, 0, 0 }, [3]i32{ 0, -1, 0 }, [3]i32{ 0, 0, 1 } }, // 4
    Rotation{ [3]i32{ -1, 0, 0 }, [3]i32{ 0, 0, 1 }, [3]i32{ 0, 1, 0 } }, // 5
    Rotation{ [3]i32{ -1, 0, 0 }, [3]i32{ 0, 1, 0 }, [3]i32{ 0, 0, -1 } }, // 6
    Rotation{ [3]i32{ -1, 0, 0 }, [3]i32{ 0, 0, -1 }, [3]i32{ 0, -1, 0 } }, // 7

    // Y+
    Rotation{ [3]i32{ 0, 1, 0 }, [3]i32{ -1, 0, 0 }, [3]i32{ 0, 0, 1 } }, // 8
    Rotation{ [3]i32{ 0, 1, 0 }, [3]i32{ 0, 0, 1 }, [3]i32{ 1, 0, 0 } }, // 9
    Rotation{ [3]i32{ 0, 1, 0 }, [3]i32{ 1, 0, 0 }, [3]i32{ 0, 0, -1 } }, // 10
    Rotation{ [3]i32{ 0, 1, 0 }, [3]i32{ 0, 0, -1 }, [3]i32{ -1, 0, 0 } }, // 11

    // Y-
    Rotation{ [3]i32{ 0, -1, 0 }, [3]i32{ 1, 0, 0 }, [3]i32{ 0, 0, 1 } }, // 12
    Rotation{ [3]i32{ 0, -1, 0 }, [3]i32{ 0, 0, -1 }, [3]i32{ 1, 0, 0 } }, // 13
    Rotation{ [3]i32{ 0, -1, 0 }, [3]i32{ -1, 0, 0 }, [3]i32{ 0, 0, -1 } }, // 14
    Rotation{ [3]i32{ 0, -1, 0 }, [3]i32{ 0, 0, 1 }, [3]i32{ -1, 0, 0 } }, // 15

    // Z+
    Rotation{ [3]i32{ 0, 0, 1 }, [3]i32{ 0, 1, 0 }, [3]i32{ -1, 0, 0 } }, // 16
    Rotation{ [3]i32{ 0, 0, 1 }, [3]i32{ 1, 0, 0 }, [3]i32{ 0, 1, 0 } }, // 17
    Rotation{ [3]i32{ 0, 0, 1 }, [3]i32{ 0, -1, 0 }, [3]i32{ 1, 0, 0 } }, // 18
    Rotation{ [3]i32{ 0, 0, 1 }, [3]i32{ -1, 0, 0 }, [3]i32{ 0, -1, 0 } }, // 19

    // Z-
    Rotation{ [3]i32{ 0, 0, -1 }, [3]i32{ 0, -1, 0 }, [3]i32{ -1, 0, 0 } }, // 20
    Rotation{ [3]i32{ 0, 0, -1 }, [3]i32{ -1, 0, 0 }, [3]i32{ 0, 1, 0 } }, // 21
    Rotation{ [3]i32{ 0, 0, -1 }, [3]i32{ 0, 1, 0 }, [3]i32{ 1, 0, 0 } }, // 22
    Rotation{ [3]i32{ 0, 0, -1 }, [3]i32{ 1, 0, 0 }, [3]i32{ 0, -1, 0 } }, // 23
};

const Point = struct {
    x: i32,
    y: i32,
    z: i32,

    fn cmp(a: Point, b: Point) std.math.Order {
        if (a.x == b.x) {
            if (a.y == b.y) {
                return std.math.order(a.z, b.z);
            } else {
                return std.math.order(a.y, b.y);
            }
        } else {
            return std.math.order(a.x, b.x);
        }
    }

    fn cmpAsc(ctx: void, a: Point, b: Point) bool {
        if (a.x == b.x) {
            if (a.y == b.y) {
                return a.z < b.z;
            } else {
                return a.y < b.y;
            }
        } else {
            return a.x < b.x;
        }
    }

    fn add(a: Point, b: Point) Point {
        return .{
            .x = a.x + b.x,
            .y = a.y + b.y,
            .z = a.z + b.z,
        };
    }

    fn diff(a: Point, b: Point) Point {
        return .{
            .x = a.x - b.x,
            .y = a.y - b.y,
            .z = a.z - b.z,
        };
    }

    fn dist(a: Point, b: Point) f32 {
        var dx: f32 = @intToFloat(f32, a.x - b.x);
        var dy: f32 = @intToFloat(f32, a.y - b.y);
        var dz: f32 = @intToFloat(f32, a.z - b.z);
        return std.math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    fn manDist(a: Point, b: Point) i32 {
        var x = std.math.absInt(a.x - b.x) catch unreachable;
        var y = std.math.absInt(a.y - b.y) catch unreachable;
        var z = std.math.absInt(a.z - b.z) catch unreachable;
        return x + y + z;
    }

    fn rotate(p: Point, r: Rotation) Point {
        var x = r[0][0] * p.x + r[0][1] * p.y + r[0][2] * p.z;
        var y = r[1][0] * p.x + r[1][1] * p.y + r[1][2] * p.z;
        var z = r[2][0] * p.x + r[2][1] * p.y + r[2][2] * p.z;
        return .{ .x = x, .y = y, .z = z };
    }
};

const Scanner = struct {
    points: ArrayList(Point),
    dists: ArrayList(IdxDist),
    allocator: *Allocator,
    idx: u64,
    solved: bool = false,
    offset: Point = .{ .x = 0, .y = 0, .z = 0 },

    const IdxDist = struct {
        const Self = @This();
        dist: f32,
        a: usize,
        b: usize,

        fn cmp(a: Self, b: Self) std.math.Order {
            return std.math.order(a.dist, b.dist);
        }

        fn cmpAsc(ctx: void, a: Self, b: Self) bool {
            return a.dist < b.dist;
        }
    };

    fn init(idx: u64, allocator: *Allocator) Scanner {
        var points = ArrayList(Point).init(allocator);
        var dists = ArrayList(IdxDist).init(allocator);
        var s = Scanner{ .points = points, .dists = dists, .allocator = allocator, .idx = idx };
        return s;
    }

    fn deinit(self: Scanner) void {
        self.points.deinit();
        self.dists.deinit();
    }

    fn addPoint(self: *Scanner, point: Point) void {
        var new_idx = self.points.items.len;
        for (self.points.items) |p, idx| {
            var d = p.dist(point);
            self.dists.append(.{ .dist = d, .a = idx, .b = new_idx }) catch unreachable;
        }
        self.points.append(point) catch unreachable;
        sort(IdxDist, self.dists.items, {}, IdxDist.cmpAsc);
    }

    fn distsMatchCount(self: Scanner, other: Scanner) u64 {
        var count: u64 = 0;
        var a = self.dists.items;
        var b = other.dists.items;
        var idx: usize = 0;
        var jdx: usize = 0;
        while (idx < a.len and jdx < b.len) {
            if (std.math.approxEqAbs(f32, a[idx].dist, b[jdx].dist, 0.001)) {
                count += 1;
                idx += 1;
                jdx += 1;
            } else if (a[idx].dist < b[jdx].dist) {
                idx += 1;
            } else if (a[idx].dist > b[jdx].dist) {
                jdx += 1;
            }
        }
        return count;
    }

    fn rotateAndMatch(self: *Scanner, other: *Scanner) void {
        var candidates_a = ArrayList(Point).init(self.allocator);
        var candidates_b = ArrayList(Point).init(self.allocator);
        defer candidates_a.deinit();
        defer candidates_b.deinit();

        // Obtain candidates.
        {
            var points_a = self.points.items;
            var points_b = other.points.items;
            var flags_a = self.allocator.alloc(u64, points_a.len) catch unreachable;
            var flags_b = self.allocator.alloc(u64, points_b.len) catch unreachable;
            defer self.allocator.free(flags_a);
            defer self.allocator.free(flags_b);

            std.mem.set(u64, flags_a, 0);
            std.mem.set(u64, flags_b, 0);

            var dists_a = self.dists.items;
            var dists_b = other.dists.items;
            var idx: usize = 0;
            var jdx: usize = 0;
            while (idx < dists_a.len and jdx < dists_b.len) {
                var da = dists_a[idx];
                var db = dists_b[jdx];
                if (std.math.approxEqAbs(f32, da.dist, db.dist, 0.001)) {
                    // print("Match: {} {} {} {}\n", .{da.a, da.b, db.a, db.b});
                    flags_a[da.a] += 1;
                    flags_a[da.b] += 1;
                    flags_b[db.a] += 1;
                    flags_b[db.b] += 1;
                    if (flags_a[da.a] == 10) candidates_a.append(points_a[da.a]) catch unreachable;
                    if (flags_a[da.b] == 10) candidates_a.append(points_a[da.b]) catch unreachable;
                    if (flags_b[db.a] == 10) candidates_b.append(points_b[db.a]) catch unreachable;
                    if (flags_b[db.b] == 10) candidates_b.append(points_b[db.b]) catch unreachable;
                    idx += 1;
                    jdx += 1;
                } else if (da.dist < db.dist) {
                    idx += 1;
                } else if (da.dist > db.dist) {
                    jdx += 1;
                }
            }

            sort(Point, candidates_a.items, {}, Point.cmpAsc);
            sort(Point, candidates_b.items, {}, Point.cmpAsc);

            assert(candidates_a.items.len > 10);
            assert(candidates_b.items.len > 10);
            assert(candidates_a.items.len == candidates_b.items.len);
        }

        // Try all rotations and sort.
        {
            var rot_answer: ?Rotation = null;
            var offset_answer: ?Point = null;
            var rot_idx: usize = 0;
            var q = candidates_b.items[0];

            var old_orient = candidates_a.items;
            var new_orient = self.allocator.alloc(Point, candidates_b.items.len) catch unreachable;
            defer self.allocator.free(new_orient);
            for (rotations) |r, ridx| {
                for (candidates_b.items) |p, idx| {
                    new_orient[idx] = p.rotate(r);
                }

                q = new_orient[0];
                sort(Point, new_orient, {}, Point.cmpAsc);
                var offset = old_orient[0].diff(new_orient[0]);

                for (old_orient) |p, idx| {
                    if (p.diff(new_orient[idx]).cmp(offset) != .eq) break;
                } else {
                    rot_answer = r;
                    offset_answer = offset;
                    rot_idx = ridx;
                    break;
                }
            }

            if (rot_answer) |rot| {
                var offset = offset_answer.?;
                print("Offset found: {d} {d} {d} (R: {})\n", .{ offset.x, offset.y, offset.z, rot_idx });
                for (other.points.items) |*p, idx| {
                    p.* = p.rotate(rot).add(offset);
                }
                other.solved = true;
                other.offset = offset;
            }
        }
    }
};

fn parseScannerName(line: []const u8) u64 {
    print("{s}\n", .{line});
    var splits = split(line, " ");
    _ = splits.next().?;
    _ = splits.next().?;
    return parseInt(u64, splits.next().?, 0) catch unreachable;
}

fn printPoints(points: []Point) void {
    for (points) |p| {
        print("{d},{d},{d}\n", .{ p.x, p.y, p.z });
    }
    print("\n", .{});
}

fn printScannerSorted(scanner: Scanner) void {
    var points = gpa.alloc(Point, scanner.points.items.len) catch unreachable;
    defer gpa.free(points);
    std.mem.copy(Point, points, scanner.points.items);
    sort(Point, points, {}, Point.cmpAsc);

    print("--- scanner {} ({}) - {d},{d},{d} ---\n", .{ scanner.idx, scanner.solved, scanner.offset.x, scanner.offset.y, scanner.offset.z });
    printPoints(points);
}

const Answer = struct {
    part1: usize,
    part2: i32,
};

fn compute(data: []const u8) Answer {
    var lines = tokenize(data, "\r\n");
    var scanners = ArrayList(Scanner).init(gpa);
    defer {
        for (scanners.items) |s| {
            s.deinit();
        }
        scanners.deinit();
    }

    var line0 = lines.next().?;
    var active_scanner = Scanner.init(parseScannerName(line0), gpa);
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line[0..3], "---")) {
            scanners.append(active_scanner) catch unreachable;
            active_scanner = Scanner.init(parseScannerName(line), gpa);
        } else {
            var splits = split(line, ",");
            var x = parseInt(i32, splits.next().?, 0) catch unreachable;
            var y = parseInt(i32, splits.next().?, 0) catch unreachable;
            var z = parseInt(i32, splits.next().?, 0) catch unreachable;
            var p = Point{ .x = x, .y = y, .z = z };
            active_scanner.addPoint(p);
        }
    }
    scanners.append(active_scanner) catch unreachable;

    // Print Graph.
    {
        print("   ", .{});
        for (scanners.items) |a, idx| {
            print(" {d: >2}", .{idx});
        }
        for (scanners.items) |a, idx| {
            print("\n{d: >2}:", .{idx});
            for (scanners.items) |b, jdx| {
                if (idx != jdx) {
                    var d = a.distsMatchCount(b);
                    if (d > 60) {
                        print(" {d: >2}", .{d});
                    } else {
                        print("   ", .{});
                    }
                } else {
                    print("   ", .{});
                }
            }
        }
        print("\n\n", .{});
    }

    // Rotate and solve scanners.
    {
        scanners.items[0].solved = true;
        printScannerSorted(scanners.items[0]);
        var solved_count: usize = 1;
        while (solved_count < scanners.items.len) {
            for (scanners.items) |*a| {
                if (a.*.solved) continue;
                for (scanners.items) |*b| {
                    if (!b.*.solved) continue;
                    if (a.distsMatchCount(b.*) < 60) continue;

                    b.rotateAndMatch(a);
                    printScannerSorted(a.*);
                    solved_count += 1;
                    break;
                }
            }
        }
    }

    var answer = Answer{ .part1 = 0, .part2 = 0 };
    // Count points.
    {
        var all_points = AutoHashMap(Point, bool).init(gpa);
        defer all_points.deinit();
        for (scanners.items) |s| {
            for (s.points.items) |p| {
                all_points.put(p, true) catch unreachable;
            }
        }
        answer.part1 = all_points.count();
    }

    // Dist scanners.
    {
        var result: i32 = 0;
        for (scanners.items) |a| {
            for (scanners.items) |b| {
                result = max(result, a.offset.manDist(b.offset));
            }
        }
        answer.part2 = result;
    }

    return answer;
}

pub fn main() !void {
    const data = @embedFile("../data/puzzle/day19.txt");
    var answer = compute(data);
    print("Part 1: {}\n", .{answer.part1});
    print("Part 2: {}\n", .{answer.part2});
}

test "sample data" {
    const data = @embedFile("../data/test/day19.txt");
    var answer = compute(data);
    try std.testing.expectEqual(answer.part1, 79);
    try std.testing.expectEqual(answer.part2, 3621);
}
