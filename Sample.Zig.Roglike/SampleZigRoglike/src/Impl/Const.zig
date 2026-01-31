const c = @import("TCOD/c.zig").c;
const Player = @import("GameObject/Player.zig");
const Inventory = @import("GameObject/Components/Inventory.zig");
const Monster = @import("GameObject/Monster.zig");
const Item = @import("GameObject/Item.zig");

pub const Color = struct {
    pub const DARK_WALL: c.TCOD_ColorRGBA = .{ .r = 0x00, .g = 0x00, .b = 0x64, .a = 255 };
    pub const DARK_GROUND: c.TCOD_ColorRGBA = .{ .r = 0x32, .g = 0x32, .b = 0x96, .a = 255 };

    pub const WHITE: c.TCOD_ColorRGB = .{ .r = 0xFF, .g = 0xFF, .b = 0xFF };
    pub const BLACK: c.TCOD_ColorRGB = .{ .r = 0x00, .g = 0x00, .b = 0x00 };
    pub const RED: c.TCOD_ColorRGBA = .{ .r = 0xFF, .g = 0x00, .b = 0x00, .a = 255 };

    pub const ATK_PLAYER: c.TCOD_ColorRGB = .{ .r = 0xE0, .g = 0xE0, .b = 0xE0 };
    pub const ATK_ENEMY: c.TCOD_ColorRGBA = .{ .r = 0xFF, .g = 0xC0, .b = 0xC0, .a = 255 };
    pub const NEED_TARGET: c.TCOD_ColorRGBA = .{ .r = 0x3F, .g = 0xFF, .b = 0xFF, .a = 255 };
    pub const STATUS_EFFECT_APPLIED: c.TCOD_ColorRGBA = .{ .r = 0x3F, .g = 0xFF, .b = 0x3F, .a = 255 };
    pub const DESCEND: c.TCOD_ColorRGBA = .{ .r = 0x9F, .g = 0x3F, .b = 0xFF, .a = 255 };

    pub const DIE_PLAYER: c.TCOD_ColorRGB = .{ .r = 0xFF, .g = 0x30, .b = 0x30 };
    pub const DIE_ENEMY: c.TCOD_ColorRGB = .{ .r = 0xFF, .g = 0xA0, .b = 0x30 };

    pub const INVALID: c.TCOD_ColorRGBA = .{ .r = 0xFF, .g = 0xFF, .b = 0x00, .a = 255 };
    pub const IMPOSSIBLE: c.TCOD_ColorRGBA = .{ .r = 0x80, .g = 0x80, .b = 0x80, .a = 255 };
    pub const ERROR: c.TCOD_ColorRGBA = .{ .r = 0xFF, .g = 0x40, .b = 0x40, .a = 255 };

    pub const WELCOME_TEXT: c.TCOD_ColorRGB = .{ .r = 0x20, .g = 0xA0, .b = 0xFF };
    pub const HEALTH_RECOVER: c.TCOD_ColorRGBA = .{ .r = 0x00, .g = 0xFF, .b = 0x00, .a = 255 };

    pub const BAR_TEXT: c.TCOD_ColorRGB = WHITE;
    pub const BAR_FILLED: c.TCOD_ColorRGB = .{ .r = 0x00, .g = 0x60, .b = 0x00 };
    pub const BAR_EMPTY: c.TCOD_ColorRGB = .{ .r = 0x40, .g = 0x10, .b = 0x10 };

    pub const MENU_TITLE: c.TCOD_ColorRGBA = .{ .r = 255, .g = 255, .b = 63, .a = 255 };
    pub const MENU_TEXT: c.TCOD_ColorRGBA = c.TCOD_white;
};

pub const E_RENDER_ORDER = enum(i32) {
    CORPSE = 0,
    ITEM = 1,
    ACTOR = 2,
};

pub const ERR_ACTION = error{
    NOTHING_TO_ATTACK,
    THAT_WAY_IS_BLOCKED,
    INVENTORY_IS_FULL,
    NOTHING_PICKUP,
    YOUR_HEALTH_IS_ALREADY_FULL,
};

pub const ERR_ACTION_to_Msg = struct {
    pub const data = .{
        .{ .key = ERR_ACTION.NOTHING_TO_ATTACK, .value = "Nothing to attack." },
        .{ .key = ERR_ACTION.THAT_WAY_IS_BLOCKED, .value = "That way is blocked." },
        .{ .key = ERR_ACTION.INVENTORY_IS_FULL, .value = "Your inventory is full." },
        .{ .key = ERR_ACTION.NOTHING_PICKUP, .value = "There is nothing here to pick up." },
        .{ .key = ERR_ACTION.YOUR_HEALTH_IS_ALREADY_FULL, .value = "Your health is already full." },
    };

    pub fn Get(key: ERR_ACTION) ?[]const u8 {
        inline for (data) |entry| {
            if (entry.key == key) {
                return entry.value;
            }
        }
        return null;
    }
};

pub const PLAYER = Player{
    ._tileComponent = .{
        .name = "Player",
        .char = '@',
        .color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
        .blocks_movement = true,
    },
    ._status = .{
        ._hp = 30,
        ._hp_max = 30,
        ._defence = 2,
        ._power = 5,
    },
    ._level = .{ .level_up_base = 200 },
    ._inventory = Inventory.Init(4),
};

pub const ORC = Monster{
    ._tileComponent = .{
        .name = "Orc",
        .char = 'o',
        .color = .{ .r = 63, .g = 127, .b = 63, .a = 255 },
        .blocks_movement = true,
    },
    ._status = .{
        ._hp = 10,
        ._hp_max = 10,
        ._defence = 0,
        ._power = 3,
    },
};

pub const TROLL = Monster{
    ._tileComponent = .{
        .name = "Troll",
        .char = 'T',
        .color = .{ .r = 0, .g = 127, .b = 0, .a = 255 },
        .blocks_movement = true,
    },
    ._status = .{
        ._hp = 16,
        ._hp_max = 16,
        ._defence = 1,
        ._power = 4,
    },
};

pub const HEALING_POTION = Item{
    ._tileComponent = .{
        .name = "Healing Potion",
        .char = '!',
        .color = .{ .r = 127, .g = 0, .b = 255, .a = 255 },
        .blocks_movement = false,
        .renderOrder = .ITEM,
    },
    ._item = .{
        .healingPotion = .{
            ._amount = 10,
        },
    },
};

pub const LIGHTING_SCROLL = Item{
    ._tileComponent = .{
        .name = "Lightning Scroll",
        .char = '~',
        .color = .{ .r = 255, .g = 255, .b = 0, .a = 255 },
        .blocks_movement = false,
        .renderOrder = .ITEM,
    },
    ._item = .{ .lightingScroll = .{} },
};

pub const CONFUSION_SCROLL = Item{
    ._tileComponent = .{
        .name = "Confusion Scroll",
        .char = '~',
        .color = .{ .r = 207, .g = 63, .b = 255, .a = 255 },
        .blocks_movement = false,
        .renderOrder = .ITEM,
    },
    ._item = .{ .confusionScroll = .{} },
};

pub const FIREBALL_SCROLL = Item{
    ._tileComponent = .{
        .name = "Fireball Scroll",
        .char = '~',
        .color = .{ .r = 255, .g = 0, .b = 0, .a = 255 },
        .blocks_movement = false,
        .renderOrder = .ITEM,
    },
    ._item = .{ .fireBallScroll = .{} },
};
