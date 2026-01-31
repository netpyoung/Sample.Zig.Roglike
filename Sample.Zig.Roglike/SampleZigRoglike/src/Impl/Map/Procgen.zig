const std = @import("std");

const c = @import("../TCOD/c.zig").c;
const SeedRandom = @import("../SeedRandom.zig");
const int2 = @import("../int2.zig");

const RectangularRoom = @import("RectangularRoom.zig");
const Map = @import("Map.zig");
const Tile = @import("Tile.zig");

pub fn GenerateDungeon(
    allocator: std.mem.Allocator,
    random: *SeedRandom,
    map: *Map,
    max_rooms: usize,
    room_min_size: usize,
    room_max_size: usize,
) void {
    map.rooms.ensureTotalCapacityPrecise(allocator, max_rooms) catch unreachable;

    outer: for (0..max_rooms) |_| {
        const room_width = random.NextUsize(room_min_size, room_max_size);
        const room_height = random.NextUsize(room_min_size, room_max_size);

        const x = random.NextUsize(0, map.width - room_width - 1);
        const y = random.NextUsize(0, map.height - room_height - 1);
        const new_room = RectangularRoom.init(x, y, room_width, room_height);
        for (map.rooms.items) |other_room| {
            if (new_room.intersects(&other_room)) {
                continue :outer;
            }
        }

        Fill(map, new_room, Tile.E_TILE_TYPE.FLOOR);
        if (map.rooms.items.len != 0) {
            TunnelBetween(random, map, map.rooms.items[map.rooms.items.len - 1].center(), new_room.center());
        }
        map.rooms.append(allocator, new_room) catch unreachable;
    }
}

fn Fill(map: *Map, room: RectangularRoom, tileId: Tile.E_TILE_TYPE) void {
    const w = map.width;
    for (room.y1 + 1..room.y2) |y| {
        const from = y * w + room.x1 + 1;
        const to = y * w + room.x2;
        @memset(map.arr[from..to], tileId);
    }
}

fn TunnelBetween(random: *SeedRandom, map: *Map, start: int2, end: int2) void {
    var iter = Iterator_tunnel.Init(random, start, end);
    while (iter.next()) |p| {
        const idx: usize = @as(usize, @intCast(p.y)) * map.width + @as(usize, @intCast(p.x));
        map.arr[idx] = Tile.E_TILE_TYPE.FLOOR;
    }
}

const Iterator_tunnel = struct {
    a: Iterator_bresenham,
    b: Iterator_bresenham,

    pub fn Init(random: *SeedRandom, start: int2, end: int2) Iterator_tunnel {
        var corner: int2 = undefined;
        const x1 = start.x;
        const y1 = start.y;
        const x2 = end.x;
        const y2 = end.y;
        if (random.NextPerc() < 0.5) { //   # 50% chance.
            // # Move horizontally, then vertically.
            corner.x = x2;
            corner.y = y1;
        } else {
            // # Move vertically, then horizontally.
            corner.x = x1;
            corner.y = y2;
        }

        return .{
            .a = Iterator_bresenham.init(start, corner),
            .b = Iterator_bresenham.init(corner, end),
        };
    }

    pub fn next(self: *Iterator_tunnel) ?int2 {
        if (self.a.next()) |ap| {
            return ap;
        }

        if (self.b.next()) |bp| {
            return bp;
        }

        return null;
    }

    const Iterator_bresenham = struct {
        // https://libtcod.readthedocs.io/en/latest/base-toolkits/line_drawing.html
        start: int2,
        end: int2,
        bresenham_data: c.TCOD_bresenham_data_t,

        pub fn init(start: int2, end: int2) Iterator_bresenham {
            var bresenham_data: c.TCOD_bresenham_data_t = undefined;
            c.TCOD_line_init_mt(start.x, start.y, end.x, end.y, &bresenham_data);

            return .{
                .start = start,
                .end = end,
                .bresenham_data = bresenham_data,
            };
        }

        pub fn next(self: *Iterator_bresenham) ?int2 {
            var x: i32 = undefined;
            var y: i32 = undefined;
            const isReached = c.TCOD_line_step_mt(&x, &y, &self.bresenham_data);
            if (isReached) {
                return null;
            }
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);

            return int2.init(x, y);
        }
    };
};
