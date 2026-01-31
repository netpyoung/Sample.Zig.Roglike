const c = @import("../TCOD/c.zig").c;

const Game = @import("../Game.zig");
const int2 = @import("../int2.zig");
const Input = @import("../Input.zig");

const Select_Lookup = @This();
game: *Game,
_isClose: bool,
mp: int2,

pub fn Init(game: *Game) Select_Lookup {
    return .{
        .game = game,
        ._isClose = false,
        .mp = game.player.GetPos(),
    };
}

pub fn Deinit(self: *Select_Lookup) void {
    _ = self;
}

pub fn IsClose(self: *Select_Lookup) bool {
    return self._isClose;
}

pub fn Update(self: *Select_Lookup) void {
    if (!self.game.input.GetMousePositionDelta().equal(int2.zero)) {
        self.mp = self.game.input.GetMousePosition();
    }

    if (self.game.input.GetMouseButtonDown(.LEFT)) {
        self.OnConfirmed();
        self._isClose = true;
        return;
    }

    if (MOVE_KEYS.Get(self.game)) |p| {
        var modifier: i32 = 1;

        if (self.game.input.GetKey(.LSHIFT) and self.game.input.GetKey(.RSHIFT)) {
            modifier *= 5;
        }

        if (self.game.input.GetKey(.LCTRL) and self.game.input.GetKey(.RCTRL)) {
            modifier *= 10;
        }

        if (self.game.input.GetKey(.LALT) and self.game.input.GetKey(.RALT)) {
            modifier *= 20;
        }

        var newmp = self.mp;
        newmp.x += p.x * modifier;
        newmp.y += p.y * modifier;
        newmp.x = @max(0, @min(newmp.x, self.game.map.width - 1));
        newmp.y = @max(0, @min(newmp.y, self.game.map.height - 1));
        self.mp = newmp;
        return;
    }

    if (CONFIRM_KEYS.Get(self.game)) {
        self.OnConfirmed();
        self._isClose = true;
        return;
    }

    if (ASK_KEYS.Get(self.game)) {
        return;
    }

    if (self.game.input.IsAnyKeyOrMouseDown()) {
        self._isClose = true;
    }
}

pub fn RenderSelection(self: *const Select_Lookup) void {
    const p = self.mp;

    const tile = self.game.tcod.console.Tiles(p.x, p.y);
    tile.bg = .{ .r = 0xFF, .g = 0xFF, .b = 0xFF, .a = 0xFF };
    tile.fg = .{ .r = 0x00, .g = 0x00, .b = 0x00, .a = 0xFF };
}

// =============

fn OnConfirmed(self: *const Select_Lookup) void {
    const mp = self.mp;
    _ = mp;
}

const MOVE_KEYS = struct {
    const data = .{
        .{ .key = Input.E_KEYCODE.UP, .value = int2.init(0, -1) },
        .{ .key = Input.E_KEYCODE.DOWN, .value = int2.init(0, 1) },
        .{ .key = Input.E_KEYCODE.LEFT, .value = int2.init(-1, 0) },
        .{ .key = Input.E_KEYCODE.RIGHT, .value = int2.init(1, 0) },
    };

    pub fn Get(game: *const Game) ?int2 {
        inline for (data) |entry| {
            if (game.input.GetKeyDown(entry.key)) {
                return entry.value;
            }
        }
        return null;
    }
};

const CONFIRM_KEYS = struct {
    const data = .{
        .{ .key = Input.E_KEYCODE.RETURN },
        .{ .key = Input.E_KEYCODE.KP_ENTER },
    };

    pub fn Get(game: *const Game) bool {
        inline for (data) |entry| {
            if (game.input.GetKeyDown(entry.key)) {
                return true;
            }
        }
        return false;
    }
};

const ASK_KEYS = struct {
    const data = .{
        .{ .key = Input.E_KEYCODE.LSHIFT },
        .{ .key = Input.E_KEYCODE.RSHIFT },
        .{ .key = Input.E_KEYCODE.LCTRL },
        .{ .key = Input.E_KEYCODE.RCTRL },
        .{ .key = Input.E_KEYCODE.LALT },
        .{ .key = Input.E_KEYCODE.RALT },
    };

    pub fn Get(game: *const Game) bool {
        inline for (data) |entry| {
            if (game.input.GetKeyDown(entry.key)) {
                return true;
            }
        }
        return false;
    }
};
