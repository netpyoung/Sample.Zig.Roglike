const Game = @import("../Game.zig");
const Select_Lookup = @import("Select_Lookup.zig");

const Selection = @This();
_game: *Game,
_selectModeOrNull : ?SelectMode = null,

const SelectMode = union(enum) {
    lookup: Select_Lookup,

    pub fn Deinit(self: *SelectMode) void {
        switch (self.*) {
            inline else => |*x| x.Deinit(),
        }
    }
    pub fn IsClose(self: *SelectMode) bool {
        return switch (self.*) {
            inline else => |*x| x.IsClose(),
        };
    }
    pub fn Update(self: *SelectMode) void {
        switch (self.*) {
            inline else => |*x| x.Update(),
        }
    }
    pub fn RenderSelection(self: *const SelectMode) void {
        switch (self.*) {
            inline else => |*x| x.RenderSelection(),
        }
    }
};

pub fn IsShowing(self: *const Selection) bool {
    return self._selectModeOrNull != null;
}

pub fn Update(self: *Selection) void {
    if (self._selectModeOrNull) |*x| {
        x.Update();
        if (x.IsClose()) {
            x.Deinit();
            self._selectModeOrNull = null;
        }
    }
}

pub fn RenderSelection(self: *const Selection) void {
    if (self._selectModeOrNull) |*x| {
        x.RenderSelection();
    }
}

// ================

pub fn Lookup(self: *Selection) void {
    self._selectModeOrNull = .{
        .lookup = Select_Lookup.Init(self._game),
    };
}
