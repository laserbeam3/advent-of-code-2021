const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/test/day16.txt");

const HexToIntReader = struct {
    const Self = @This();

    raw: []const u8,
    offset: usize = 0,
    val: u4 = 0,
    bits_left: u3 = 0,
    total_bits_read: usize = 0,

    fn readInt(self: *Self, comptime T: type) T {
        const total_bit_count: usize = @typeInfo(T).Int.bits;
        var return_bit_count: usize = total_bit_count;
        var result: T = 0;

        while (return_bit_count > 0) {
            if (self.bits_left == 0) {
                self.val = parseInt(u4, self.raw[self.offset .. self.offset + 1], 16) catch unreachable;
                self.offset += 1;
                self.bits_left = 4;
                // print("Read: {0x} {0b:0>4}\n", .{self.val});
            }

            if (return_bit_count >= self.bits_left) {
                if (result > 0) result <<= @intCast(Log2Int(T), self.bits_left);
                result |= @intCast(T, self.val);
                self.val = 0;
                return_bit_count -= self.bits_left;
                self.total_bits_read += self.bits_left;
                self.bits_left = 0;
            } else {
                var shift: u2 = @intCast(u2, self.bits_left - return_bit_count);
                var x = self.val >> shift;
                if (result > 0) result <<= @intCast(Log2Int(T), return_bit_count);
                result |= @intCast(T, x);
                self.bits_left = shift;
                self.total_bits_read += return_bit_count;
                return_bit_count = 0;
                switch (self.bits_left) {
                    0 => self.val = 0,
                    1 => self.val &= 0b1,
                    2 => self.val &= 0b11,
                    3 => self.val &= 0b111,
                    else => {},
                }
            }
        }

        return result;
    }
};

const Packet = struct {
    const Self = @This();
    version: u3 = 0,
    id: u3 = 0,
    value: i64 = 0,
    length_type: u1 = 0,
    length_val: u15 = 0,
    bit_length: usize = 0,
    sub_packets: ArrayList(Packet),

    fn init(allocator: *Allocator) Packet {
        return .{
            .sub_packets = ArrayList(Packet).init(allocator),
        };
    }

    fn deinit(self: Self) void {
        for (self.sub_packets.items) |p| {
            p.deinit();
        }
        self.sub_packets.deinit();
    }
};

fn readPacket(reader: *HexToIntReader, allocator: *Allocator) Packet {
    var result = Packet.init(allocator);
    result.version = reader.readInt(u3);
    result.id = reader.readInt(u3);
    result.bit_length = 6;

    if (result.id == 4) {
        var num: i64 = 0;
        var part = reader.readInt(u5);
        while (part & (1 << 4) != 0) {
            num |= (part & 0b1111);
            num <<= 4;
            result.bit_length += 5;
            part = reader.readInt(u5);
        }
        num |= part & 0b1111;
        result.value = num;
        result.bit_length += 5;

    } else {
        result.length_type = reader.readInt(u1);
        result.bit_length += 1;

        if (result.length_type == 0) {
            var subpacket_length = reader.readInt(u15);
            result.bit_length += 15;
            result.length_val = subpacket_length;

            var children_length: usize = 0;
            while (children_length < subpacket_length) {
                var p = readPacket(reader, allocator);
                result.sub_packets.append(p) catch unreachable;
                children_length += p.bit_length;
                result.bit_length += p.bit_length;
            }
        } else {
            var subpacket_count = reader.readInt(u11);
            result.bit_length += 11;
            result.length_val = subpacket_count;

            var idx: u11 = 0;
            while (idx < subpacket_count) : (idx += 1) {
                var p = readPacket(reader, allocator);
                result.sub_packets.append(p) catch unreachable;
                result.bit_length += p.bit_length;
            }
        }
    }

    return result;
}

fn printPacket(p: Packet, depth: usize) void {
    var idx: usize = 0;
    while (idx < depth) : (idx += 1) {
        print(" ", .{});
    }
    var symbol: u8 = ' ';
    switch (p.id) {
        0 => symbol = '+',
        1 => symbol = '*',
        2 => symbol = 'v',
        3 => symbol = '^',
        4 => symbol = ' ',
        5 => symbol = '>',
        6 => symbol = '<',
        7 => symbol = '=',
    }

    if (p.id == 4) {
        print("{0}-{0b:0>3} {1c} {2}\n", .{ p.version, symbol, p.value });
    } else {
        print("{0}-{0b:0>3} {1c} {4} ({2} {3})\n", .{ p.version, symbol, p.length_type, p.length_val, p.sub_packets.items.len });
    }
}

fn printPacketTree(packet: Packet, depth: usize) void {
    printPacket(packet, depth);
    if (packet.id != 4) {
        for (packet.sub_packets.items) |p| {
            printPacketTree(p, depth + 2);
        }
    }
}

fn versionSum(packet: Packet) u64 {
    var result: u64 = packet.version;
    for (packet.sub_packets.items) |p| {
        result += versionSum(p);
    }
    return result;
}

fn evalPacket(packet: Packet) i64 {
    switch (packet.id) {
        0 => {
            var result = evalPacket(packet.sub_packets.items[0]);
            for (packet.sub_packets.items[1..]) |p| {
                result += evalPacket(p);
            }
            return result;
        },
        1 => {
            var result = evalPacket(packet.sub_packets.items[0]);
            for (packet.sub_packets.items[1..]) |p| {
                result *= evalPacket(p);
            }
            return result;
        },
        2 => {
            var result = evalPacket(packet.sub_packets.items[0]);
            for (packet.sub_packets.items[1..]) |p| {
                result = min(result, evalPacket(p));
            }
            return result;
        },
        3 => {
            var result = evalPacket(packet.sub_packets.items[0]);
            for (packet.sub_packets.items[1..]) |p| {
                result = max(result, evalPacket(p));
            }
            return result;
        },
        4 => {
            return packet.value;
        },
        5 => {
            var a = evalPacket(packet.sub_packets.items[0]);
            var b = evalPacket(packet.sub_packets.items[1]);
            if (a > b) return 1;
            return 0;
        },
        6 => {
            var a = evalPacket(packet.sub_packets.items[0]);
            var b = evalPacket(packet.sub_packets.items[1]);
            if (a < b) return 1;
            return 0;
        },
        7 => {
            var a = evalPacket(packet.sub_packets.items[0]);
            var b = evalPacket(packet.sub_packets.items[1]);
            if (a == b) return 1;
            return 0;
        },
    }
}

pub fn main() !void {
    var input = tokenize(data, "\r\n").next().?;
    var reader: HexToIntReader = .{ .raw = input };
    var root_packet = readPacket(&reader, gpa);
    defer root_packet.deinit();
    printPacketTree(root_packet, 0);
    print("Version sum: {}\n", .{versionSum(root_packet)});
    print("Eval: {}\n", .{evalPacket(root_packet)});
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
const Log2Int = std.math.Log2Int;

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
