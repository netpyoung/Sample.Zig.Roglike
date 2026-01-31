const std = @import("std");

const c = @import("../TCOD/c.zig").c;
const Game = @import("../Game.zig");

const Console = @import("../TCOD/Console.zig");

const Popup_CharacterScreen = @This();
_game: *Game,
_isClose: bool,

pub fn Init(game: *Game) Popup_CharacterScreen {
    return .{
        ._game = game,
        ._isClose = false,
    };
}

pub fn Deinit(self: *Popup_CharacterScreen) void {
    _ = self;
}

pub fn IsClose(self: *const Popup_CharacterScreen) bool {
    return self._isClose;
}

pub fn Update(self: *Popup_CharacterScreen) void {
    if (self._game.input.IsAnyKeyOrMouseDown()) {
        self._isClose = true;
    }
}

pub fn RenderPopup(self: *const Popup_CharacterScreen) void {
    const x: i32 = if (self._game.player.GetPos().x <= 30) 40 else 0;
    const y: i32 = 0;

    const title = "Character Information";
    const width = title.len + 4;
    const height = 7;

    const console = &self._game.tcod.console;
    console.DrawFrame(
        title,
        .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .fg = &c.TCOD_white,
            .bg = &c.TCOD_black,
        },
        true,
    );

    const player = &self._game.player;
    var buf: [32]u8 = undefined;
    var msg: [:0]u8 = undefined;
    msg = std.fmt.bufPrintZ(&buf, "Level: {d}", .{player._level.current_level}) catch unreachable;
    console.Print(msg, .{ .x = x + 1, .y = y + 1 });

    msg = std.fmt.bufPrintZ(&buf, "XP: {d}", .{player._level.current_level}) catch unreachable;
    console.Print(msg, .{ .x = x + 1, .y = y + 2 });

    msg = std.fmt.bufPrintZ(&buf, "XP for next Level: {d}", .{player._level.experience_to_next_level}) catch unreachable;
    console.Print(msg, .{ .x = x + 1, .y = y + 3 });

    msg = std.fmt.bufPrintZ(&buf, "Attack: {d}", .{player._level.current_level}) catch unreachable;
    console.Print(msg, .{ .x = x + 1, .y = y + 4 });

    msg = std.fmt.bufPrintZ(&buf, "Defense: {d}", .{player._level.current_level}) catch unreachable;
    console.Print(msg, .{ .x = x + 1, .y = y + 5 });
}
