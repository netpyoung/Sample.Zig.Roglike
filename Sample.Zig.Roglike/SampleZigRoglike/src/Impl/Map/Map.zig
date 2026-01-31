const std = @import("std");

const int2 = @import("../int2.zig");
const SeedRandom = @import("../SeedRandom.zig");
const c = @import("../TCOD/c.zig").c;
const Console = @import("../TCOD/Console.zig");
const Tile = @import("Tile.zig");
const Procgen = @import("Procgen.zig");
const RectangularRoom = @import("RectangularRoom.zig");

const Map = @This();
width: usize,
height: usize,
arr: []Tile.E_TILE_TYPE,
arr_visible: []bool, // TODO(pyoung): use console.map directly?
arr_explored: []bool,
rooms: std.ArrayList(RectangularRoom),

pub fn Init(allocator: std.mem.Allocator, width: usize, height: usize) Map {
    const arr: []Tile.E_TILE_TYPE = allocator.alloc(Tile.E_TILE_TYPE, width * height) catch unreachable;
    @memset(arr, Tile.E_TILE_TYPE.WALL);

    const arr_visible: []bool = allocator.alloc(bool, width * height) catch unreachable;
    @memset(arr_visible, false);

    const arr_explored: []bool = allocator.alloc(bool, width * height) catch unreachable;
    @memset(arr_explored, false);

    return .{
        .width = width,
        .height = height,
        .arr = arr,
        .arr_visible = arr_visible,
        .arr_explored = arr_explored,
        .rooms = std.ArrayList(RectangularRoom).empty,
    };
}

pub fn Deinit(self: *Map, allocator: std.mem.Allocator) void {
    self.rooms.deinit(allocator);
    allocator.free(self.arr_explored);
    allocator.free(self.arr_visible);
    allocator.free(self.arr);
}

pub fn NewDungeon(self: *Map, allocator: std.mem.Allocator, random: *SeedRandom) void {
    const max_rooms = 30;
    const room_min_size = 6;
    const room_max_size = 10;

    Procgen.GenerateDungeon(allocator, random, self, max_rooms, room_min_size, room_max_size);
}

pub fn IsMoveable(self: *const Map, p: int2) bool {
    const idx = @as(usize, @intCast(p.y)) * self.width + @as(usize, @intCast(p.x));
    const x = self.arr[idx];

    const tile = x.GetTile();
    const isWalkable = tile.isWalkable;
    return isWalkable;
}

pub fn Iter(self: *Map) Iterator_ConsoleTile {
    return .{ .curIdx = 0, .maxIdx = self.arr.len, .map = self };
}

pub const Iterator_ConsoleTile = struct {
    curIdx: usize,
    maxIdx: usize,
    map: *const Map,

    pub const IterResult = struct {
        idx: usize,
        tile: *const c.TCOD_ConsoleTile,
    };

    pub fn Next(self: *Iterator_ConsoleTile) ?IterResult {
        if (self.curIdx >= self.maxIdx) {
            return null;
        }
        const idx = self.curIdx;
        self.curIdx += 1;

        const x = self.map.arr[idx];
        const tile = x.GetTile();
        if (self.map.arr_visible[idx]) {
            return .{ .idx = idx, .tile = &tile.tile_light };
        }

        if (self.map.arr_explored[idx]) {
            return .{ .idx = idx, .tile = &tile.tile_dark };
        }

        // return .{ .idx = idx, .tile = &tile.tile_light };
        return .{ .idx = idx, .tile = &Tile.TILE_SHROUD };
    }
};

pub fn UpdateFOV(self: *Map, p: int2, console: *Console) void {
    var iter = self.IterTransparent();
    var idx: usize = 0;
    while (iter.next()) |b| {
        console.map.*.cells[idx].transparent = b;
        idx += 1;
    }

    const radius = 8;
    const light_walls = true;
    const algo = c.FOV_PERMISSIVE_0;
    const err = c.TCOD_map_compute_fov(console.map, p.x, p.y, radius, light_walls, algo);
    _ = err;

    for (0..self.arr_visible.len) |i| {
        self.arr_visible[i] = console.map.*.cells[i].fov;
    }

    self.updateExploredSimd();
}

fn updateExploredSimd(self: *Map) void {
    const len = self.arr.len;
    const vec_size = 32;
    const chunks = len / vec_size;

    for (0..chunks) |i| {
        const offset = i * vec_size;
        const visible_v: @Vector(vec_size, bool) = self.arr_visible[offset..][0..vec_size].*;
        const explored_v: @Vector(vec_size, bool) = self.arr_explored[offset..][0..vec_size].*;
        self.arr_explored[offset..][0..vec_size].* = explored_v | visible_v;
    }

    for (chunks * vec_size..len) |i| {
        self.arr_explored[i] |= self.arr_visible[i];
    }
}

// ====
pub fn IterTransparent(self: *const Map) Iterator_Transparent {
    return .{
        .curIdx = 0,
        .maxIdx = self.width * self.height,
        .map = self,
    };
}

pub const Iterator_Transparent = struct {
    curIdx: usize,
    maxIdx: usize,
    map: *const Map,

    pub fn next(self: *Iterator_Transparent) ?bool {
        if (self.curIdx >= self.maxIdx) {
            return null;
        }
        const x = @intFromEnum(self.map.arr[self.curIdx]);
        const isTransparent = Tile.Tiles[x].isTransparent;
        self.curIdx += 1;
        return isTransparent;
    }
};
