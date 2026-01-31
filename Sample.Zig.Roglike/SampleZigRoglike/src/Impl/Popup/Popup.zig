const Game = @import("../Game.zig");
const Popup_MessageLogHistory = @import("Popup_MessageLogHistory.zig");
const Popup_Inventory = @import("Popup_Inventory.zig");
const Popup_CharacterScreen = @import("Popup_CharacterScreen.zig");

const Popup = @This();
_game: *Game,
_popupWindowOrNull: ?PopupWindow = null,

const PopupWindow = union(enum) {
    messageLogHistory: Popup_MessageLogHistory,
    inventory: Popup_Inventory,
    charcterScreen: Popup_CharacterScreen,

    pub fn Deinit(self: *PopupWindow) void {
        switch (self.*) {
            inline else => |*x| x.Deinit(),
        }
    }
    pub fn IsClose(self: *PopupWindow) bool {
        return switch (self.*) {
            inline else => |*x| x.IsClose(),
        };
    }
    pub fn Update(self: *PopupWindow) void {
        switch (self.*) {
            inline else => |*x| x.Update(),
        }
    }
    pub fn RenderPopup(self: *const PopupWindow) void {
        switch (self.*) {
            inline else => |*x| x.RenderPopup(),
        }
    }
};

pub fn IsShowing(self: *const Popup) bool {
    return self._popupWindowOrNull != null;
}

pub fn Update(self: *Popup) void {
    if (self._popupWindowOrNull) |*popup| {
        popup.Update();
        if (popup.IsClose()) {
            popup.Deinit();
            self._popupWindowOrNull = null;
        }
    }
}

pub fn RenderPopup(self: *const Popup) void {
    if (self._popupWindowOrNull) |*popup| {
        popup.RenderPopup();
    }
}

// ================

pub fn ShowHistory(self: *Popup) void {
    self._popupWindowOrNull = .{
        .messageLogHistory = Popup_MessageLogHistory.Init(self._game),
    };
}

pub fn ShowInventoryUse(self: *Popup) void {
    self._popupWindowOrNull = .{
        .inventory = Popup_Inventory.Init(self._game, .ITEM_USE),
    };
}

pub fn ShowInventoryDrop(self: *Popup) void {
    self._popupWindowOrNull = .{
        .inventory = Popup_Inventory.Init(self._game, .ITEM_DROP),
    };
}

pub fn ShowCharacterScreen(self: *Popup) void {
    self._popupWindowOrNull = .{
        .charcterScreen = Popup_CharacterScreen.Init(self._game),
    };
}
