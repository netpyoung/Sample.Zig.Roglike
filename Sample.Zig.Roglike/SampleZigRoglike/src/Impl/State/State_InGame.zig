const std = @import("std");

const c = @import("../TCOD/c.zig").c;
const int2 = @import("../int2.zig");
const Const = @import("../Const.zig");
const Game = @import("../Game.zig");
const Input = @import("../Input.zig");

const State_InGame = @This();

pub fn Update(_: *const State_InGame, game: *Game) void {
    if (!game.player.IsAlive()) {
        return;
    }

    if (game.selection.IsShowing()) {
        game.selection.Update();
        return;
    }

    if (game.popup.IsShowing()) {
        game.popup.Update();
        return;
    }

    if (game.input.GetKeyDown(.ESCAPE)) {
        game.is_quit = true;
        return;
    }

    if (!_HandleUserInput(game)) {
        return;
    }

    game.PerformMonstersAI();
    game.map.UpdateFOV(game.player.GetPos(), &game.tcod.console);
}

pub fn Render(_: *const State_InGame, game: *Game) void {
    // render map
    var iter = game.map.Iter();
    while (iter.Next()) |x| {
        game.tcod.console.tiles[x.idx] = x.tile.*;
    }

    _RenderPlayerHpBar(game);
    _RenderNamesAtMouseLocation(game);

    game.messageLog.RenderAll(game.allocator, &game.tcod.console, 21, 45, 40, 5);

    var miter = game.monsters.iterator(0);
    while (miter.next()) |m| {
        const p = m.GetPos();
        const idx = @as(usize, @intCast(p.y)) * game.map.width + @as(usize, @intCast(p.x));
        if (game.map.arr_visible[idx]) {
            m.Render(&game.tcod.console);
        }
    }

    for (game.items.items) |m| {
        const p = m.GetPos();
        const idx = @as(usize, @intCast(p.y)) * game.map.width + @as(usize, @intCast(p.x));
        if (game.map.arr_visible[idx]) {
            m.Render(&game.tcod.console);
        }
        m.Render(&game.tcod.console);
    }

    game.player.Render(&game.tcod.console);

    if (game.popup.IsShowing()) {
        game.popup.RenderPopup();
    }
    if (game.selection.IsShowing()) {
        game.selection.RenderSelection();
    }
}

// ===========================
fn _RenderPlayerHpBar(game: *Game) void {
    const current_value: i32 = game.player._status._hp;
    const maximum_value: i32 = game.player._status._hp_max;

    const total_width: i32 = 20;
    game.tcod.console.DrawRect(.{ .x = 0, .y = 45, .width = total_width, .height = 1 }, 1, .{ .bg = &Const.Color.BAR_EMPTY });

    const bar_width: i32 = @intFromFloat(@as(f32, @floatFromInt(current_value)) / @as(f32, @floatFromInt(maximum_value)) * @as(f32, @floatFromInt(total_width)));
    if (bar_width > 0) {
        game.tcod.console.DrawRect(.{ .x = 0, .y = 45, .width = bar_width, .height = 1 }, 1, .{ .bg = &Const.Color.BAR_FILLED });
    }

    var buf: [32]u8 = undefined;
    const msg = std.fmt.bufPrintZ(&buf, "HP: {d}/{d}", .{ current_value, maximum_value }) catch unreachable;
    game.tcod.console.Print(msg, .{ .x = 1, .y = 45, .fg = &Const.Color.BAR_TEXT });
}

fn _RenderNamesAtMouseLocation(game: *const Game) void {
    var buf: [32]u8 = undefined;
    const names = game.GetNamesAtMouseLocation(&buf);
    if (std.mem.eql(u8, names, "")) {
        return;
    }

    const p = int2.init(21, 44);
    game.tcod.console.Print(names, .{ .x = p.x, .y = p.y });
    //    _ = c.TCOD_printn_rgb(con, .{ .x = p.x, .y = p.y, .width = 0, .height = 0, .alignment = c.TCOD_LEFT, .fg = &c.TCOD_white, .bg = 0, .flag = c.TCOD_BKGND_SET }, @intCast(names.len), names.ptr);
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

const WAIT_KEYS = struct {
    const data = .{
        .{ .key = Input.E_KEYCODE.PERIOD },
        .{ .key = Input.E_KEYCODE.KP_5 },
        .{ .key = Input.E_KEYCODE.CLEAR },
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

fn _HandleUserInput(game: *Game) bool {
    // arrow - move
    if (MOVE_KEYS.Get(game)) |p| {
        game.Action_MoveOrMeleeAttack(p);
        return true;
    }

    // period/KP_5/CLEAR - wait
    if (WAIT_KEYS.Get(game)) {
        return true;
    }

    // v - history view
    if (game.input.GetKeyDown(.V)) {
        game.Action_ShowHistory();
        return false;
    }

    // g - pikcup
    if (game.input.GetKeyDown(.G)) {
        game.Action_Pickup();
        return true;
    }
    // i - inventory
    if (game.input.GetKeyDown(.I)) {
        game.Action_InventoryOpen();
        return false;
    }
    // d - inventory drop
    if (game.input.GetKeyDown(.D)) {
        game.Action_InventoryDrop();
        return false;
    }
    // c - character screen
    if (game.input.GetKeyDown(.C)) {
        game.Action_CharacterScreen();
        return false;
    }
    // / - look
    if (game.input.GetKeyDown(.SLASH)) {
        game.Action_Look();
        return false;
    }
    return false;
}
