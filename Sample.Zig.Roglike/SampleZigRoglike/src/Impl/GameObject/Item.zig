const TileComponent = @import("Components/TileComponent.zig");
const Console = @import("../TCOD/Console.zig");
const int2 = @import("../int2.zig");
const Game = @import("../Game.zig");

const Item = @This();
_tileComponent: TileComponent,
_item: ItemGroup,

pub fn Render(self: *const Item, console: *const Console) void {
    self._tileComponent.Render(console);
}

pub fn GetPos(self: *const Item) int2 {
    return self._tileComponent.pos;
}

pub fn SetPos(self: *Item, p: int2) void {
    self._tileComponent.pos = p;
}

pub fn Activate(self: *const Item, game: *Game) void {
    self._item.Activate(self, game);
}

// ============

const Item_HealingPotion = @import("Item/Item_HealingPotion.zig");
const Item_LightingScroll = @import("Item/Item_LightingScroll.zig");
const Item_ConfusionScroll = @import("Item/Item_ConfusionScroll.zig");
const Item_FireBallScroll = @import("Item/Item_FireBallScroll.zig");

pub const ItemGroup = union(enum) {
    healingPotion: Item_HealingPotion,
    lightingScroll: Item_LightingScroll,
    confusionScroll: Item_ConfusionScroll,
    fireBallScroll: Item_FireBallScroll,

    pub fn Activate(self: *const ItemGroup, item: *const Item, game: *Game) void {
        switch (self.*) {
            inline else => |*x| x.Activate(item, game),
        }
    }
};

