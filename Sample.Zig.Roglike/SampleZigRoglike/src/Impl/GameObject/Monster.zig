const std = @import("std");

const Console = @import("../TCOD/Console.zig");
const int2 = @import("../int2.zig");

const TileComponent = @import("Components/TileComponent.zig");
const Status = @import("Components/Status.zig");
const AI = @import("Components/AI/AI.zig").AI;

const Monster = @This();
_tileComponent: TileComponent,
_status: Status,
_aiOrNull: ?AI = null,

pub fn Deinit(self: *Monster) void {
    if (self._aiOrNull == null) {
    return;
    }
    self._aiOrNull.?.Deinit();
}

pub fn Render(self: *const Monster, console: *const Console) void {
    self._tileComponent.Render(console);
}

pub fn IsAlive(self: *const Monster) bool {
    return self._status._hp > 0;
}

pub fn GetPos(self: *const Monster) int2 {
    return self._tileComponent.pos;
}

pub fn SetPos(self: *Monster, p: int2) void {
    self._tileComponent.pos = p;
}

pub fn AddDamange(self: *Monster, x: i32) i32 {
    self._status._hp -= x;
    if (self._status._hp == 0) {
        self.Dead();
    }
    return self._status._hp;
}

pub fn Dead(self: *Monster) void {
    self._tileComponent.blocks_movement = false;
    self._tileComponent.char = '%';
    self._tileComponent.color = .{ .r = 191, .g = 0, .b = 0, .a = 255 };
}

pub fn format(self: *const Monster, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("{s}", .{self._tileComponent.name});
}
