const std = @import("std");

const Game = @import("Impl/Game.zig");

const print = std.debug.print;

pub fn main() !void {
    var game: Game = undefined;
    try Game.Init(&game);
    defer game.Deinit();

    while (game.IsRunning()) {
        game.Update();
        game.Render();
    }
}
