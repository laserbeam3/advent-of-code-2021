const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

// const data = @embedFile("../data/test/day04.txt");

const Score = struct {
    value: u64,
    lastCell: u64,
    time: u64,
};

fn printBoard(board: [5][5]u64) void {
    print("----\n", .{});
    print("{d: >2} {d: >2} {d: >2} {d: >2} {d: >2}\n", .{ board[0][0], board[0][1], board[0][2], board[0][3], board[0][4] });
    print("{d: >2} {d: >2} {d: >2} {d: >2} {d: >2}\n", .{ board[1][0], board[1][1], board[1][2], board[1][3], board[1][4] });
    print("{d: >2} {d: >2} {d: >2} {d: >2} {d: >2}\n", .{ board[2][0], board[2][1], board[2][2], board[2][3], board[2][4] });
    print("{d: >2} {d: >2} {d: >2} {d: >2} {d: >2}\n", .{ board[3][0], board[3][1], board[3][2], board[3][3], board[3][4] });
    print("{d: >2} {d: >2} {d: >2} {d: >2} {d: >2}\n", .{ board[4][0], board[4][1], board[4][2], board[4][3], board[4][4] });
    print("\n", .{});
}

fn scoreBoard(board: [5][5]u64, scores: []u64) Score {
    var used = [5][5]u64{
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
    };

    for (scores) |score, time| {
        for (board) |row, ridx| {
            for (row) |cell, cidx| {
                if (cell != score) continue;
                used[ridx][cidx] = 1;

                var idx: u64 = 0;
                var rowWise: bool = true;
                var colWise: bool = true;
                while (idx < 5) {
                    defer idx += 1;
                    if (used[ridx][idx] == 0) colWise = false;
                    if (used[idx][cidx] == 0) rowWise = false;
                    if (!rowWise and !colWise) break;
                } else {
                    // printBoard(used);
                    var result: u64 = 0;
                    for (board) |row2, ridx2| {
                        for (row2) |cell2, cidx2| {
                            result += (1 - used[ridx2][cidx2]) * cell2;
                        }
                    }
                    return Score{
                        .value = result * score,
                        .lastCell = score,
                        .time = time,
                    };
                }
            }
        }
    }
    return Score{ .value = 0, .lastCell = 0, .time = 0 };
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("data/puzzle/day04.txt", .{});
    defer file.close();
    var data = file.readToEndAlloc(gpa, 1024 * 1024 * 16) catch unreachable;
    defer gpa.free(data);

    var lines = tokenize(data, "\r\n");
    var scores_str = split(lines.next().?, ",");
    var scores_list = ArrayList(u64).init(gpa);
    defer scores_list.deinit();
    while (scores_str.next()) |score_str| {
        var score = parseInt(u64, score_str, 10) catch unreachable;
        scores_list.append(score) catch unreachable;
    }
    const scores = scores_list.items;
    var board = [5][5]u64{
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
        [_]u64{ 0, 0, 0, 0, 0 },
    };

    var bestScore: Score = .{ .value = 0, .lastCell = 0, .time = 999999 };
    var worstScore: Score = .{ .value = 0, .lastCell = 0, .time = 0 };

    while (lines.next()) |test_line| {
        // Part 1
        var line = test_line;
        var ridx: u64 = 0;
        while (ridx < 5) {
            defer ridx += 1;
            if (ridx != 0) {
                line = lines.next().?;
            }

            var words = split(line, " ");
            var cidx: u64 = 0;
            while (cidx < 5) {
                defer cidx += 1;

                var word = words.next().?;
                while (word.len == 0) {
                    word = words.next().?;
                }
                board[ridx][cidx] = parseInt(u64, word, 10) catch unreachable;
            }
        }
        var score = scoreBoard(board, scores);
        if (score.time < bestScore.time) {
            bestScore = score;
        }
        if (score.time > worstScore.time) {
            worstScore = score;
        }
    }
    print("{} {} {}\n", .{ bestScore.value, bestScore.lastCell, bestScore.time });
    print("{} {} {}\n", .{ worstScore.value, worstScore.lastCell, worstScore.time });
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
