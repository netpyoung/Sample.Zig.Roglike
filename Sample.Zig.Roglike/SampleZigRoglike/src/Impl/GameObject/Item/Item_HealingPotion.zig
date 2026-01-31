const std = @import("std");

const TileComponent = @import("../Components/TileComponent.zig");
const Console = @import("../../TCOD/Console.zig");
const int2 = @import("../../int2.zig");
const Game = @import("../../Game.zig");
const Const = @import("../../Const.zig");
const Item = @import("../Item.zig");

const Item_HealingPotion = @This();
_amount: i32,

pub fn Activate(self: *const Item_HealingPotion, item: *const Item, game: *Game) void {
    var player = &game.player;
    const hp = player._status._hp;
    const nexthp = @min(hp + self._amount, player._status._hp_max);

    const amount_recovered = nexthp - player._status._hp;
    if (amount_recovered == 0) {
        game.messageLog.AddMessage("Your health is already full.", Const.Color.WELCOME_TEXT, true);
        return;
    }

    player._status._hp = nexthp;

    var buf: [64]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "You consume the {s}, and recover {d} HP!", .{ item._tileComponent.name, amount_recovered }) catch unreachable;
    game.messageLog.AddMessage(msg, Const.Color.WELCOME_TEXT, true);
}
