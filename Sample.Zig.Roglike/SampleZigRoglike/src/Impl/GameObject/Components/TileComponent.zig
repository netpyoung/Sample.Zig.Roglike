const c = @import("../../TCOD/c.zig").c;
const Console = @import("../../TCOD/Console.zig");
const Const = @import("../../Const.zig");
const int2 = @import("../../int2.zig");

const TileComponent = @This();

name: [] const u8,
pos: int2 = int2.one,
char: u8,
color: c.TCOD_ColorRGBA,
renderOrder: Const.E_RENDER_ORDER = Const.E_RENDER_ORDER.ACTOR,
blocks_movement: bool,

pub fn Render(self: *const TileComponent, console: *const Console) void {
    const tile = console.Tiles(self.pos.x, self.pos.y);
    tile.fg = self.color;
    tile.ch = self.char;
}
