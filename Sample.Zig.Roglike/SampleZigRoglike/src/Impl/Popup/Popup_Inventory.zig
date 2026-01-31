const std = @import("std");

const c = @import("../TCOD/c.zig").c;
const Game = @import("../Game.zig");

const Console = @import("../TCOD/Console.zig");

const Popup_Inventory = @This();
_game: *Game,
_isClose: bool,
_openType: E_OPEN_TYPE,
TITLE: []const u8,

const E_OPEN_TYPE = enum {
    ITEM_USE,
    ITEM_DROP,
};

pub fn Init(game: *Game, openType: E_OPEN_TYPE) Popup_Inventory {
    return switch (openType) {
        .ITEM_USE => .{
            ._game = game,
            ._isClose = false,
            ._openType = openType,
            .TITLE = "Select an item to use",
        },
        .ITEM_DROP => .{
            ._game = game,
            ._isClose = false,
            ._openType = openType,
            .TITLE = "Select an item to drop",
        },
    };
}

pub fn Deinit(self: *Popup_Inventory) void {
    _ = self;
}

pub fn IsClose(self: *const Popup_Inventory) bool {
    return self._isClose;
}

pub fn Update(self: *Popup_Inventory) void {
    if (!self._game.input.IsAnyKeyOrMouseDown()) {
        return;
    }

    if (!self._game.input.IsAlphaKeyDown()) {
        self._isClose = true;
        return;
    }

    // const idx = key - c.SDLK_A;
    const idx = 0;
    const player = &self._game.player;
    const items = player._inventory._items.items;
    if (idx >= items.len) {
        return;
    }

    const item = &items[idx];

    switch (self._openType) {
        .ITEM_USE => {
            self._game.Action_UseItem(item);
        },
        .ITEM_DROP => {
            self._game.Action_RemoveItem(item);
        },
    }
}

pub fn RenderPopup(self: *const Popup_Inventory) void {
    const player = &self._game.player;
    const items = player._inventory._items.items;
    const number_of_items_in_inventory = items.len;

    const isEmpty = number_of_items_in_inventory <= 0;
    const x: i32 = if (player.GetPos().x <= 30) 40 else 0;
    const y: i32 = 0;
    const width: i32 = @intCast(self.TITLE.len + 4);
    const height: i32 = @intCast(@max(3, number_of_items_in_inventory + 2));

    const console = &self._game.tcod.console;
    console.DrawFrame(self.TITLE, .{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .fg = &c.TCOD_white,
        .bg = &c.TCOD_black,
    }, true);

    if (isEmpty) {
        console.Print("(Empty)", .{ .x = x + 1, .y = y + 1 });
        return;
    }

    var buf: [32]u8 = undefined;
    for (0.., items) |i, *item| {
        const ch = 'a' + @as(u8, @intCast(i));
        const name = item._tileComponent.name;
        const msg = std.fmt.bufPrintZ(&buf, "{c}) {s}", .{ ch, name }) catch unreachable;

        const xx = x + 1;
        const yy = y + @as(i32, @intCast(i)) + 1;
        console.Print(msg, .{ .x = xx, .y = yy, .width = 0, .height = 1 });
    }
}
