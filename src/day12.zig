const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;
const LoggingAllocator = std.heap.LoggingAllocator;

const util = @import("util.zig");
const gpa = util.gpa_log;

const data = @embedFile("../data/puzzle/day12.txt");

const NodeFlags = u64;
const NodeName = []const u8;

const Graph = struct {
    const Self = @This();
    const NodeId = u6;

    const NodeData = struct {
        name: NodeName,
        id: NodeId,
        minor: bool,
    };

    const Edge = struct {
        from: NodeData,
        to: NodeData,
        weight: u64 = 1,
    };

    nodes: StringHashMap(NodeData),
    edges: AutoHashMap(NodeId, AutoHashMap(NodeId, Edge)),

    allocator: *Allocator,
    minor_nodes_count: u64 = 0,
    start_node_idx: usize = 0,
    end_node_idx: usize = 0,

    fn init(allocator: *Allocator) Self {
        return .{
            .nodes = StringHashMap(NodeData).init(allocator),
            .edges = AutoHashMap(NodeId, AutoHashMap(NodeId, Edge)).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Self) void {
        var it1 = self.edges.valueIterator();
        while (it1.next()) |value_ptr| {
            value_ptr.deinit();
        }
        var it2 = self.nodes.valueIterator();
        while (it2.next()) |value_ptr| {
            self.allocator.free(value_ptr.name);
        }
        self.nodes.deinit();
        self.edges.deinit();
    }

    fn createNode(self: *Self, key: NodeName) void {
        var own_key = self.allocator.alloc(u8, key.len) catch unreachable;
        std.mem.copy(u8, own_key, key);

        var is_minor = (own_key[0] >= 'a' and own_key[0] <= 'z');
        var id = @intCast(u6, self.nodes.count());
        self.nodes.put(own_key, NodeData{
            .name = own_key,
            .minor = is_minor,
            .id = id,
        }) catch unreachable;

        var node_list = AutoHashMap(NodeId, Edge).init(self.allocator);
        self.edges.put(id, node_list) catch unreachable;
    }

    fn addEdge(self: *Self, name_a: NodeName, name_b: NodeName) void {
        if (!self.nodes.contains(name_a)) {
            self.createNode(name_a);
        }
        if (!self.nodes.contains(name_b)) {
            self.createNode(name_b);
        }

        var a = self.nodes.get(name_a).?;
        var b = self.nodes.get(name_b).?;
        self.edges.getPtr(a.id).?.put(b.id, Edge{ .from = a, .to = b }) catch unreachable;
        self.edges.getPtr(b.id).?.put(a.id, Edge{ .from = b, .to = a }) catch unreachable;
    }

    fn printGraph(self: *Self) void {
        print("Nodes\n", .{});
        var it1 = self.nodes.valueIterator();
        while (it1.next()) |node_ptr| {
            print("{s} ({} {})\n", .{ node_ptr.name, node_ptr.minor, node_ptr.id });
        }

        print("\nEdges\n", .{});
        var it2 = self.nodes.valueIterator();
        while (it2.next()) |node_ptr| {
            var node_list = self.edges.get(node_ptr.id).?;
            print("{s} ({}):", .{ node_ptr.name, node_list.count() });

            var it3 = self.edgeIterator(node_ptr.name);
            while (it3.next()) |edge| {
                print(" {s}({})", .{ edge.to.name, edge.weight });
            }
            print("\n", .{});
        }
        print("\n", .{});
    }

    fn computeWeights(self: *Self) void {
        var iterator1 = self.nodes.valueIterator();
        while (iterator1.next()) |node_data_ptr| {
            if (node_data_ptr.minor) continue;

            // print("{s} {s}\n", .{ node_data_ptr.name, node_data_ptr });
            var nbr = ArrayList(NodeData).init(gpa);
            defer nbr.deinit();
            var edge_it1 = self.edgeIterator(node_data_ptr.name);
            while (edge_it1.next()) |edge_1_ptr| {
                nbr.append(edge_1_ptr.to) catch unreachable;
            }

            var idx1: usize = 0;
            while (idx1 < nbr.items.len) : (idx1 += 1) {
                const node_1 = nbr.items[idx1];

                if (self.getEdgePtrById(node_1.id, node_1.id)) |edge| {
                    edge.weight += 1;
                } else {
                    self.addEdge(node_1.name, node_1.name);
                }

                var idx2: usize = idx1 + 1;
                while (idx2 < nbr.items.len) : (idx2 += 1) {
                    const node_2 = nbr.items[idx2];
                    if (self.getEdgePtrById(node_1.id, node_2.id)) |edge| {
                        edge.weight += 1;
                        self.getEdgePtrById(node_2.id, node_1.id).?.weight += 1;
                    } else {
                        self.addEdge(node_1.name, node_2.name);
                    }
                }
            }
        }
    }

    fn getEdgePtrById(self: *Self, a: NodeId, b: NodeId) ?*Edge {
        return self.edges.getPtr(a).?.getPtr(b);
    }

    fn getEdgePtr(self: *Self, name_a: NodeName, name_b: NodeName) ?*Edge {
        const a = self.nodes.get(name_a).?;
        const b = self.nodes.get(name_b).?;
        return self.edges.getPtr(a.id).?.getPtr(b.id);
    }

    const EdgeIterator = AutoHashMap(NodeId, Edge).ValueIterator;
    const NodeIterator = StringHashMap(NodeData).ValueIterator;

    fn edgeIterator(self: *Self, node_name: NodeName) EdgeIterator {
        const node = self.nodes.get(node_name).?;
        const edges = self.edges.get(node.id).?;
        return edges.valueIterator();
    }

    fn nodeIterator(self: *Self) NodeIterator {
        return self.nodes.valueIterator();
    }
};

fn countRoutesTo(graph: *Graph, to: NodeName, ignore_flags: u64) u64 {
    if (std.mem.eql(u8, to, "start")) return 1;
    var node = graph.nodes.get(to).?;
    if (!node.minor) return 0;

    var it = graph.edgeIterator(to);
    var result: u64 = 0;
    var new_flag = ignore_flags | @as(u64, 1) << node.id;
    while (it.next()) |edge| {
        if (!edge.to.minor) continue;
        if (edge.to.id == node.id) continue;
        if (ignore_flags & @as(u64, 1) << edge.to.id != 0) continue;
        result += countRoutesTo(graph, edge.to.name, new_flag) * edge.weight;
    }
    return result;
}

const RouteStep = struct {
    name: NodeName,
    weight: u64,
};

fn countRoutesToWithDupes(graph: *Graph, to: NodeName, ignore_flags: u64, duplicated: bool, route: *ArrayList(RouteStep)) u64 {
    if (std.mem.eql(u8, to, "start")) {
        // var idx: usize = route.items.len;
        // var k: u64 = 1;
        // while (idx > 0) : (idx -= 1) {
        //     k *= route.items[idx - 1].weight;
        // }

        // print("{: >3} start", .{k});
        // idx = route.items.len;
        // while (idx > 0) : (idx -= 1) {
        //     const x = route.items[idx - 1];
        //     print("-{}-{s}", .{ x.weight, x.name });
        // }
        // print("\n", .{});
        return 1;
    }
    var node = graph.nodes.get(to).?;
    if (!node.minor) return 0;

    var result: u64 = 0;
    var new_flag = ignore_flags | @as(u64, 1) << node.id;

    var it = graph.edgeIterator(to);
    while (it.next()) |edge| {
        if (!edge.to.minor) continue;
        if (std.mem.eql(u8, edge.to.name, "end")) continue;
        if (edge.to.id == node.id) {
            if (duplicated) continue;
            route.append(.{ .name = to, .weight = edge.weight }) catch unreachable;
            result += countRoutesToWithDupes(graph, edge.to.name, new_flag, true, route) * edge.weight;
            var q = route.popOrNull();
        } else {
            if (ignore_flags & @as(u64, 1) << edge.to.id != 0) {
                if (duplicated) continue;
                route.append(.{ .name = to, .weight = edge.weight }) catch unreachable;
                result += countRoutesToWithDupes(graph, edge.to.name, new_flag, true, route) * edge.weight;
                var q = route.popOrNull();
            } else {
                route.append(.{ .name = to, .weight = edge.weight }) catch unreachable;
                result += countRoutesToWithDupes(graph, edge.to.name, new_flag, duplicated, route) * edge.weight;
                var q = route.popOrNull();
            }
        }
    }
    return result;
}

pub fn main() !void {
    var lines = tokenize(data, "\r\n");
    var score: u64 = 0;
    var graph = Graph.init(gpa);
    defer graph.deinit();

    while (lines.next()) |line| {
        var words = split(line, "-");
        const a = words.next().?;
        const b = words.next().?;
        graph.addEdge(a, b);
    }
    graph.printGraph();
    graph.computeWeights();
    graph.printGraph();

    print("\nResults 1\n", .{});
    print("{s} {}\n", .{ "end", countRoutesTo(&graph, "end", 0) });

    print("\nResults 2\n", .{});
    var route = ArrayList(RouteStep).init(gpa);
    defer route.deinit();
    print("{s} {}\n", .{ "end", countRoutesToWithDupes(&graph, "end", 0, false, &route) });
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
