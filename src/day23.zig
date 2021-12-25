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

const Loc = struct {
    x: u32,
    y: u32,

    fn hash(self: Loc) u32 {
        if (self.y == 0) return self.x;
        var col = self.x / 2 - 1;
        return 12 + 4 * self.y + col;
    }

    fn dist(a: Loc, b: Loc) u32 {
        var x: u32 = undefined;
        var y: u32 = undefined;

        if (a.x > b.x) {
            x = a.x - b.x;
        } else {
            x = b.x - a.x;
        }

        if (a.y > b.y) {
            y = a.y - b.y;
        } else {
            y = b.y - a.y;
        }

        if (a.y > 0 and b.y > 0 and a.x != b.x) y *= 2;

        return x + y;
    }

    fn asc(a: Loc, b: Loc) bool {
        if (a.y == b.y) return a.x < b.x;
        return a.y < b.y;
    }
};
const LocGroup = [4]Loc;
const ArrayForm = [16]Loc;

const Map = struct {
    AA: LocGroup,
    BB: LocGroup,
    CC: LocGroup,
    DD: LocGroup,

    fn hash(self: Map) u128 {
        var self_array: ArrayForm = @bitCast(ArrayForm, self);
        var f: u128 = 1;
        var r: u128 = 0;
        for (self_array) |val| {
            r += (val.hash() * f);
            f *= 32;
        }
        return r;
    }

    const heuristic_permutations = [_][4]u32{
        [4]u32{ 1, 2, 3, 0 },
        [4]u32{ 1, 2, 0, 3 },
        [4]u32{ 1, 3, 2, 0 },
        [4]u32{ 1, 3, 0, 2 },
        [4]u32{ 1, 0, 2, 3 },
        [4]u32{ 1, 0, 3, 2 },
        [4]u32{ 2, 1, 3, 0 },
        [4]u32{ 2, 1, 0, 3 },
        [4]u32{ 2, 3, 1, 0 },
        [4]u32{ 2, 3, 0, 1 },
        [4]u32{ 2, 0, 1, 3 },
        [4]u32{ 2, 0, 3, 1 },
        [4]u32{ 3, 2, 1, 0 },
        [4]u32{ 3, 2, 0, 1 },
        [4]u32{ 3, 1, 2, 0 },
        [4]u32{ 3, 1, 0, 2 },
        [4]u32{ 3, 0, 2, 1 },
        [4]u32{ 3, 0, 1, 2 },
        [4]u32{ 0, 2, 3, 1 },
        [4]u32{ 0, 2, 1, 3 },
        [4]u32{ 0, 3, 2, 1 },
        [4]u32{ 0, 3, 1, 2 },
        [4]u32{ 0, 1, 2, 3 },
        [4]u32{ 0, 1, 3, 2 },
    };

    fn locGroupDist(a: LocGroup, b: LocGroup, permutation: [4]u32) u32 {
        var idx: u32 = 0;
        var r: u32 = 0;
        while (idx < 4) : (idx += 1) {
            r += a[idx].dist(b[permutation[idx]]);
        }
        return r;
    }

    fn heuristicDist(self: Map, other: Map) u32 {
        var a0: u32 = 999999;
        var b0: u32 = 999999;
        var c0: u32 = 999999;
        var d0: u32 = 999999;
        for (Map.heuristic_permutations) |perm| {
            a0 = min(a0, Map.locGroupDist(self.AA, other.AA, perm));
            b0 = min(b0, Map.locGroupDist(self.BB, other.BB, perm));
            c0 = min(c0, Map.locGroupDist(self.CC, other.CC, perm));
            d0 = min(d0, Map.locGroupDist(self.DD, other.DD, perm));
        }
        return a0 + b0 * 10 + c0 * 100 + d0 * 1000;
    }

    fn eql(self: Map, other: Map) bool {
        return self.heuristicDist(other) == 0;
    }

    fn spaceAtHome(self: Map, dest_col: u32, node_idx: usize) u32 {
        var self_array: ArrayForm = @bitCast(ArrayForm, self);
        var result: u32 = 4;
        for (self_array) |node, idx| {
            if (idx == node_idx) continue;
            if (node.x == dest_col) {
                result = min(result, node.y - 1);
            }
        }
        return result;
    }

    fn grid(self: Map) [5][11]u8 {
        var result = std.mem.zeroes([5][11]u8);
        for (result) |*line| {
            std.mem.set(u8, line, ' ');
        }
        std.mem.set(u8, &result[0], '.');
        var ridx: u32 = 2;
        while (ridx < 10) : (ridx += 2) {
            result[1][ridx] = '.';
            result[2][ridx] = '.';
            result[3][ridx] = '.';
            result[4][ridx] = '.';
        }
        var self_array: ArrayForm = @bitCast(ArrayForm, self);
        for (self_array) |node, idx| {
            var dest_col = @divFloor(@intCast(u32, idx), 4);
            var dest_char = @intCast(u8, dest_col + 'A');
            result[node.y][node.x] = dest_char;
        }
        return result;
    }

    fn printState(self: Map) void {
        var g = self.grid();
        for (g) |line| {
            print("{s}\n", .{line});
        }
        print("\n", .{});
    }
};

const SearchState = struct {
    state: Map,
    cost: u32,
    est: u32,

    fn order(self: SearchState, other: SearchState) std.math.Order {
        return std.math.order(self.est + self.cost, other.est + other.cost);
    }

    const NextStateIterator = struct {
        const Self = @This();
        states: ArrayList(SearchState),
        idx: u32 = 0,

        fn next(self: *Self) ?SearchState {
            if (self.idx < self.states.items.len) {
                self.idx += 1;
                return self.states.items[self.idx - 1];
            } else {
                self.states.deinit();
                return null;
            }
        }
    };

    fn addStatesMoveOut(self: SearchState, states: *ArrayList(SearchState), node_idx: usize) void {
        var state_array: ArrayForm = @bitCast(ArrayForm, self.state);
        var node = state_array[node_idx];
        var dest_idx = @divFloor(@intCast(u32, node_idx), 4);
        const cost_mult = std.math.pow(u32, 10, dest_idx);

        var min_x: u32 = 0;
        var max_x: u32 = 10;
        for (state_array) |other, idx| {
            if (idx == node_idx) continue;
            if (other.y != 0) continue;
            if (other.x < node.x) min_x = max(other.x + 1, min_x);
            if (other.x > node.x) max_x = min(other.x - 1, max_x);
        }

        var new_state: ArrayForm = undefined;
        std.mem.copy(Loc, &new_state, &state_array);

        var new_x: u32 = min_x;
        while (new_x <= max_x) : (new_x += 1) {
            if (new_x == 2 or new_x == 4 or new_x == 6 or new_x == 8) continue;
            new_state[node_idx].x = new_x;
            new_state[node_idx].y = 0;

            var xxx = @bitCast(Map, new_state);
            var new_search = SearchState{
                .state = xxx,
                .cost = self.cost + cost_mult * node.dist(new_state[node_idx]),
                .est = searchHeuristic(xxx),
            };
            states.append(new_search) catch unreachable;
        }
    }

    fn nextStates(self: SearchState) NextStateIterator {
        var states = ArrayList(SearchState).init(gpa);
        var state_array: ArrayForm = @bitCast(ArrayForm, self.state);
        main: for (state_array) |node, idx| {
            var dest_idx = @divFloor(@intCast(u32, idx), 4);
            var dest_col = dest_idx * 2 + 2;
            switch (node.y) {
                0 => {
                    var home_depth = self.state.spaceAtHome(dest_col, idx);
                    if (home_depth == 0) continue :main;
                    var ax = node.x;
                    var ay = @intCast(u32, dest_col);
                    if (ax > ay) std.mem.swap(u32, &ax, &ay);
                    for (state_array) |other_node, other_idx| {
                        if (idx == other_idx) continue;
                        if (other_node.y == 0 and other_node.x > ax and other_node.x < ay) continue :main;
                        var other_dest_idx = @divFloor(@intCast(u32, other_idx), 4);
                        if (other_node.x == dest_col and other_dest_idx != dest_idx) continue :main;
                    }

                    var new_state: ArrayForm = undefined;
                    std.mem.copy(Loc, &new_state, &state_array);
                    new_state[idx].x = dest_col;
                    new_state[idx].y = home_depth;
                    const cost_mult = std.math.pow(u32, 10, dest_idx);

                    var xxx = @bitCast(Map, new_state);
                    var new_search = SearchState{
                        .state = xxx,
                        .cost = self.cost + cost_mult * node.dist(new_state[idx]),
                        .est = searchHeuristic(xxx),
                    };
                    states.append(new_search) catch unreachable;
                },
                1,
                2,
                3,
                4,
                => |depth| {
                    if (depth == 4 and node.x == dest_col) continue :main;
                    var local_depth = self.state.spaceAtHome(node.x, idx);
                    if (local_depth != depth) continue :main;
                    self.addStatesMoveOut(&states, idx);
                },
                else => unreachable,
            }
        }
        return NextStateIterator{ .states = states };
    }
};

// zig fmt: off
const dest = Map{
    .AA = .{.{ .x = 2, .y = 1 }, .{ .x = 2, .y = 2 }, .{ .x = 2, .y = 3 }, .{ .x = 2, .y = 4 }},
    .BB = .{.{ .x = 4, .y = 1 }, .{ .x = 4, .y = 2 }, .{ .x = 4, .y = 3 }, .{ .x = 4, .y = 4 }},
    .CC = .{.{ .x = 6, .y = 1 }, .{ .x = 6, .y = 2 }, .{ .x = 6, .y = 3 }, .{ .x = 6, .y = 4 }},
    .DD = .{.{ .x = 8, .y = 1 }, .{ .x = 8, .y = 2 }, .{ .x = 8, .y = 3 }, .{ .x = 8, .y = 4 }},
};
// zig fmt: on

fn searchHeuristic(s: Map) u32 {
    // return 0;
    var result = s.heuristicDist(dest);
    {
        var used = std.mem.zeroes([5]u32);
        for (s.DD) |val| {
            if (val.x != 8 or val.y == 0) continue;
            used[val.y] = 1;
        }
        var idx: u32 = 4;
        var flag: u32 = 0;
        while (idx > 0) : (idx -= 1) {
            if (used[idx] == 0) flag = 1;
            result += flag * used[idx] * 2000 * idx;
        }
    }
    {
        var used = std.mem.zeroes([5]u32);
        for (s.CC) |val| {
            if (val.x != 6 or val.y == 0) continue;
            used[val.y] = 1;
        }
        var idx: u32 = 4;
        var flag: u32 = 0;
        while (idx > 0) : (idx -= 1) {
            if (used[idx] == 0) flag = 1;
            result += flag * used[idx] * 200 * idx;
        }
    }
    return result;
}

fn search(start: Map) u32 {
    var queue = PriorityQueue(SearchState).init(gpa, SearchState.order);
    var visited = AutoHashMap(u128, void).init(gpa);
    var states_explored: u32 = 0;
    defer queue.deinit();
    defer visited.deinit();

    var search_start = SearchState{
        .state = start,
        .cost = 0,
        .est = searchHeuristic(start),
    };
    queue.add(search_start) catch unreachable;

    while (queue.removeOrNull()) |state| {
        if (state.state.eql(dest)) {
            print("States explored: {} {}\n", .{ states_explored, queue.count() });
            return state.cost;
        }
        var hash_val = state.state.hash();
        if (visited.contains(hash_val)) continue;
        visited.put(hash_val, {}) catch unreachable;

        states_explored += 1;
        var next_iterator = state.nextStates();
        while (next_iterator.next()) |next_state| {
            if (visited.contains(next_state.state.hash())) continue;
            queue.add(next_state) catch unreachable;
        }
        if (states_explored % 50000 == 0) {
            print("States explored: {} {}\n", .{ states_explored, queue.count() });
            print("Next state: {} {}\n", .{ state.cost, state.est });
            state.state.printState();
        }
    }
    unreachable;
}

fn parseInput(input: []const u8) Map {
    var idx_a: u32 = 0;
    var idx_b: u32 = 0;
    var idx_c: u32 = 0;
    var idx_d: u32 = 0;
    var idx: u32 = 0;
    var pos_order = [_][2]u32{
        [2]u32{ 0, 0 },
        [2]u32{ 1, 0 },
        [2]u32{ 2, 0 },
        [2]u32{ 3, 0 },
        [2]u32{ 4, 0 },
        [2]u32{ 5, 0 },
        [2]u32{ 6, 0 },
        [2]u32{ 7, 0 },
        [2]u32{ 8, 0 },
        [2]u32{ 9, 0 },
        [2]u32{ 10, 0 },
        [2]u32{ 2, 1 },
        [2]u32{ 4, 1 },
        [2]u32{ 6, 1 },
        [2]u32{ 8, 1 },
        [2]u32{ 2, 2 },
        [2]u32{ 4, 2 },
        [2]u32{ 6, 2 },
        [2]u32{ 8, 2 },
        [2]u32{ 2, 3 },
        [2]u32{ 4, 3 },
        [2]u32{ 6, 3 },
        [2]u32{ 8, 3 },
        [2]u32{ 2, 4 },
        [2]u32{ 4, 4 },
        [2]u32{ 6, 4 },
        [2]u32{ 8, 4 },
    };

    var result = std.mem.zeroes(Map);
    for (input) |char| {
        switch (char) {
            'A' => {
                result.AA[idx_a] = Loc{ .x = pos_order[idx][0], .y = pos_order[idx][1] };
                idx_a += 1;
                idx += 1;
            },
            'B' => {
                result.BB[idx_b] = Loc{ .x = pos_order[idx][0], .y = pos_order[idx][1] };
                idx_b += 1;
                idx += 1;
            },
            'C' => {
                result.CC[idx_c] = Loc{ .x = pos_order[idx][0], .y = pos_order[idx][1] };
                idx_c += 1;
                idx += 1;
            },
            'D' => {
                result.DD[idx_d] = Loc{ .x = pos_order[idx][0], .y = pos_order[idx][1] };
                idx_d += 1;
                idx += 1;
            },
            '.' => {
                idx += 1;
            },
            else => {},
        }
    }
    return result;
}

pub fn main() !void {
    {
        var s2_str =
            \\ #############
            \\ #.D.......AC#
            \\ ###C#A#.#.###
            \\   #D#C#B#.#
            \\   #D#B#A#D#
            \\   #B#A#B#C#
            \\   #########
        ;
        var s2 = parseInput(s2_str);
        s2.printState();
        var search_start = SearchState{ .state = s2, .cost = 0, .est = searchHeuristic(s2) };
        var next_iterator = search_start.nextStates();
        while (next_iterator.next()) |val| {
            print("{} {} {}: \n", .{ val.cost, val.est, val.state.hash() });
            val.state.printState();
        }
    }

    var start_str =
        \\ #############
        \\ #...........#
        \\ ###C#A#D#D###
        \\   #D#C#B#A#
        \\   #D#B#A#C#
        \\   #B#A#B#C#
        \\   #########
    ;
    var start = parseInput(start_str);
    print("{} {}\n", .{ start.heuristicDist(dest), searchHeuristic(start) });
    print("{}\n", .{search(start)});
}
