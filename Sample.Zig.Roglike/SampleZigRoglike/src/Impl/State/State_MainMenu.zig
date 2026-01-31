const std = @import("std");

const c = @import("../TCOD/c.zig").c;
const Game = @import("../Game.zig");
const StateMachine = @import("StateMachine.zig");

const State_MainMenu = @This();

pub fn Update(_: *const State_MainMenu, game: *Game) void {
    // n - play new
    // c - load
    // q - quit

    if (game.input.GetKey(.N)) {
        game.StartNewGame();
        game.sm.SetNextState(StateMachine.State{ .inGame = .{} });
        return;
    }

    if (game.input.GetKey(.Q)) {
        game.is_quit = true;
        return;
    }
}

pub fn Render(_: *const State_MainMenu, game: *Game) void {
    game.tcod.console.DrawSemigraphics(game.tcod.menu_background);

    const halfw: i32 = @divTrunc(game.tcod.console.width, 2);
    const halfh: i32 = @divTrunc(game.tcod.console.height, 2);

    game.tcod.console.Print("TOMBS OF THE ANCIENT KINGS", .{
        .x = halfw,
        .y = halfh - 4,
        .alignment = c.TCOD_CENTER,
    });

    game.tcod.console.Print("By netpyoung", .{
        .x = halfw,
        .y = game.tcod.console.height - 2,
        .height = 0,
        .alignment = c.TCOD_CENTER,
    });

    const texts = [_][:0]const u8{
        "[N] Play a new game   ",
        "[C] Continue last game",
        "[Q] Quit              ",
    };

    for (0.., texts) |i, text| {
        game.tcod.console.Print(text, .{
            .x = halfw,
            .y = halfh - 2 + @as(i32, @intCast(i)),
            .alignment = c.TCOD_CENTER,
        });
    }
}
