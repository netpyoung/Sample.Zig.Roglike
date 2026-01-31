const c = @import("../TCOD/c.zig").c;

const Tile = @This();

id: E_TILE_TYPE,
isWalkable: bool,
isTransparent: bool,
tile_dark: c.TCOD_ConsoleTile,
tile_light: c.TCOD_ConsoleTile,

pub const E_TILE_TYPE = enum(usize) {
    FLOOR,
    WALL,
    DOWNSTAIRS,

    pub fn IsWalkable(self: E_TILE_TYPE) bool {
        return Tiles[@intFromEnum(self)].isWalkable;
    }

    pub fn GetTile(self: E_TILE_TYPE) *const Tile {
        return &Tiles[@intFromEnum(self)];
    }
};

pub const TILE_SHROUD: c.TCOD_ConsoleTile = .{
    .ch = ' ',
    .fg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
    .bg = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
};

pub const Floor: Tile = .{
    .id = E_TILE_TYPE.FLOOR,
    .isWalkable = true,
    .isTransparent = true,
    .tile_dark = .{
        .ch = ' ',
        .fg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .bg = .{ .r = 50, .g = 50, .b = 150, .a = 255 },
    },
    .tile_light = .{
        .ch = ' ',
        .fg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .bg = .{ .r = 200, .g = 180, .b = 50, .a = 255 },
    },
};

pub const Wall: Tile = .{
    .id = E_TILE_TYPE.WALL,
    .isWalkable = false,
    .isTransparent = false,
    .tile_dark = .{
        .ch = ' ',
        .fg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .bg = .{ .r = 0, .g = 0, .b = 100, .a = 255 },
    },
    .tile_light = .{
        .ch = ' ',
        .fg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .bg = .{ .r = 130, .g = 110, .b = 50, .a = 255 },
    },
};

pub const DownStairs: Tile = .{
    .id = E_TILE_TYPE.DOWNSTAIRS,
    .isWalkable = true,
    .isTransparent = true,
    .tile_dark = .{
        .ch = '>',
        .fg = .{ .r = 0, .g = 0, .b = 100, .a = 255 },
        .bg = .{ .r = 50, .g = 50, .b = 150, .a = 255 },
    },
    .tile_light = .{
        .ch = '>',
        .fg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .bg = .{ .r = 200, .g = 180, .b = 50, .a = 255 },
    },
};

pub const Tiles = &[_]Tile{
    Floor,
    Wall,
    DownStairs,
};
