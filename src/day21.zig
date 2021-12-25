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

const Movement = struct {
    jump: u32,
    mult: u64,
};

var movements = [7]Movement{
    .{ .jump = 3, .mult = 1 },
    .{ .jump = 4, .mult = 3 },
    .{ .jump = 5, .mult = 6 },
    .{ .jump = 6, .mult = 7 },
    .{ .jump = 7, .mult = 6 },
    .{ .jump = 8, .mult = 3 },
    .{ .jump = 9, .mult = 1 },
};

fn score(pos: u32) u64 {
    var p: u64 = pos % 10;
    if (p == 0) return 10;
    return p;
}

pub fn main() !void {
    // paths indices:
    // 0: Score of first player
    // 1: Score of second player
    // 2: Position of first player
    // 3: Position of second player
    // 4: Next player to move (0 = first, 1 = second)
    var paths = std.mem.zeroes([31][31][10][10][2]u64);

    // Initial conditions: Both players have 0 score, and there's one universe where each player
    // is at a certain location, and the first player is next to move.
    // paths[0][0][4][8][0] = 1;  // sample
    paths[0][0][0][3][0] = 1; // input

    {
        var base_score: u32 = 0;
        while (base_score <= 40) : (base_score += 1) {
            var new_universes: u64 = 0;
            var p1_score: u32 = 0;
            while (p1_score <= base_score) : (p1_score += 1) {
                var p2_score = base_score - p1_score;
                if (p1_score > 20 or p2_score > 20) continue;

                var idx: u32 = 0;
                while (idx < 10) : (idx += 1) {
                    var jdx: u32 = 0;
                    while (jdx < 10) : (jdx += 1) {
                        for (movements) |m| {
                            // P1 to move.
                            var new_p1 = (idx + m.jump) % 10;
                            var new_s1 = p1_score + score(new_p1);
                            var x = paths[p1_score][p2_score][idx][jdx][0] * m.mult;
                            paths[new_s1][p2_score][new_p1][jdx][1] += x;
                            new_universes += x;

                            // P2 to move.
                            var new_p2 = (jdx + m.jump) % 10;
                            var new_s2 = p2_score + score(new_p2);
                            x = paths[p1_score][p2_score][idx][jdx][1] * m.mult;
                            paths[p1_score][new_s2][idx][new_p2][0] += x;
                            new_universes += x;
                        }
                    }
                }
            }

            print("base scpre: {d: >2} universes: {}\n", .{ base_score, new_universes });
        }
    }

    var p1_wins: u64 = 0;
    var p2_wins: u64 = 0;

    {
        var win_score: u32 = 21;
        while (win_score <= 30) : (win_score += 1) {
            var lose_score: u32 = 0;
            while (lose_score <= 20) : (lose_score += 1) {
                var idx: u32 = 0;
                while (idx < 10) : (idx += 1) {
                    var jdx: u32 = 0;
                    while (jdx < 10) : (jdx += 1) {
                        p1_wins += paths[win_score][lose_score][idx][jdx][0];
                        p1_wins += paths[win_score][lose_score][idx][jdx][1];
                        p2_wins += paths[lose_score][win_score][idx][jdx][0];
                        p2_wins += paths[lose_score][win_score][idx][jdx][1];
                    }
                }
            }
        }
    }

    print("P1 wins: {}\n", .{p1_wins});
    print("P2 wins: {}\n", .{p2_wins});
    print("Total: {}\n", .{p1_wins + p2_wins});
}
