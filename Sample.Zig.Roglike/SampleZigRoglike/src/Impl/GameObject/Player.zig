const std = @import("std");

const Console = @import("../TCOD/Console.zig");
const int2 = @import("../int2.zig");

const TileComponent = @import("Components/TileComponent.zig");
const Status = @import("Components/Status.zig");
const Level = @import("Components/Level.zig");
const Inventory = @import("Components/Inventory.zig");
const Monster = @import("Monster.zig");
const Item = @import("Item.zig");

const Player = @This();
_tileComponent: TileComponent,
_status: Status,
_level: Level,
_inventory: Inventory,

pub fn Deinit(self: *Player, allocator: std.mem.Allocator) void {
    self._inventory.Deinit(allocator);
}

pub fn Render(self: *const Player, console: *const Console) void {
    self._tileComponent.Render(console);
}

pub fn IsAlive(self: *const Player) bool {
    return self._status._hp > 0;
}

pub fn GetPos(self: *const Player) int2 {
    return self._tileComponent.pos;
}

pub fn SetPos(self: *Player, p: int2) void {
    self._tileComponent.pos = p;
}

pub fn AddDamange(self: *Player, x: i32) i32 {
    self._status._hp -= x;
    if (self._status._hp == 0) {
        self.Dead();
    }
    return self._status._hp;
}

pub fn Dead(self: *Player) void {
    self._tileComponent.blocks_movement = false;
    self._tileComponent.char = '%';
    self._tileComponent.color = .{ .r = 191, .g = 0, .b = 0, .a = 255 };
}

pub fn Pickup(self: *Player, allocator: std.mem.Allocator, item: *const Item) void {
    self._inventory.Add(allocator, item);
}

pub fn format(self: *const Player, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("{s}", .{self._tileComponent.name});
}