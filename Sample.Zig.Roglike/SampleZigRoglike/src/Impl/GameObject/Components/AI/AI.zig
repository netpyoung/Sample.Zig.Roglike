const Game = @import("../../../Game.zig");

const AI_HostileEnemy = @import("AI_HostileEnemy.zig");
//const AI_ConfusedEnemy = @import("AI_ConfusedEnemy.zig");

pub const AI = union(enum) {
    hostileEnemy: AI_HostileEnemy,
    // confusedEnemy: AI_ConfusedEnemy,

    pub fn Deinit(self: *AI) void {
        switch (self.*) {
            inline else => |*x| return x.Deinit(),
        }
    }

    pub fn Perform(self: *AI) void {
        return switch (self.*) {
            inline else => |*x| return x.Perform(),
        };
    }
};
