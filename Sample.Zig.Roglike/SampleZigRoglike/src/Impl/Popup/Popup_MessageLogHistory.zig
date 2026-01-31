const c = @import("../TCOD/c.zig").c;
const Game = @import("../Game.zig");

const Console = @import("../TCOD/Console.zig");
const Input = @import("../Input.zig");

const Popup_MessageLogHistory = @This();
_game: *Game,
_console: Console,
_cursor: usize,
_isClose: bool,
_log_length: usize,

pub fn Init(game: *Game) Popup_MessageLogHistory {
    const console = Console.Init(game.tcod.console.width - 6, game.tcod.console.height - 6);
    return .{
        ._game = game,
        ._console = console,
        ._cursor = game.messageLog.messages.items.len - 1,
        ._isClose = false,
        ._log_length = game.messageLog.messages.items.len,
    };
}

pub fn Deinit(self: *Popup_MessageLogHistory) void {
    self._console.Deinit();
}

pub fn IsClose(self: *const Popup_MessageLogHistory) bool {
    return self._isClose;
}

const CURSOR_Y_KEYS = struct {
    const data = .{
        .{ .key = Input.E_KEYCODE.UP, .value = -1 },
        .{ .key = Input.E_KEYCODE.DOWN, .value = 1 },
        .{ .key = Input.E_KEYCODE.PAGEUP, .value = -10 },
        .{ .key = Input.E_KEYCODE.PAGEDOWN, .value = 10 },
    };

    pub fn Get(game: *const Game) ?i32 {
        inline for (data) |entry| {
            if (game.input.GetKeyDown(entry.key)) {
                return entry.value;
            }
        }
        return null;
    }
};

pub fn Update(self: *Popup_MessageLogHistory) void {
    if (CURSOR_Y_KEYS.Get(self._game)) |adjust| {
        if (adjust < 0 and self._cursor == 0) {
            self._cursor = self._log_length - 1;
        } else if (adjust > 0 and self._cursor == self._log_length - 1) {
            self._cursor = 0;
        } else {
            self._cursor = @intCast(@max(0, @min(@as(i32, @intCast(self._cursor)) + adjust, @as(i32, @intCast(self._log_length - 1)))));
        }
        return;
    }

    if (self._game.input.GetKeyDown(.HOME)) {
        self._cursor = 0;
        return;
    }

    if (self._game.input.GetKeyDown(.END)) {
        self._cursor = self._log_length - 1;
        return;
    }

    if (self._game.input.IsAnyKeyOrMouseDown()) {
        self._isClose = true;
    }
}

pub fn RenderPopup(self: *const Popup_MessageLogHistory) void {
    const w = self._console.width;
    const h = self._console.height;

    self._console.DrawFrame("", .{ .width = w, .height = h }, true);

    const msg = "┤Message history├";
    self._console.PrintRect(msg, .{ .width = w, .height = 1, .alignment = c.TCOD_CENTER });

    const items = self._game.messageLog.messages.items[0 .. self._cursor + 1];
    self._game.messageLog.RenderMessages(self._game.allocator, &self._console, 1, 1, w - 2, h - 2, items);

    self._console.Blit(0, 0, w, h, &self._game.tcod.console, 3, 3, 1.0, 1.0);
}
