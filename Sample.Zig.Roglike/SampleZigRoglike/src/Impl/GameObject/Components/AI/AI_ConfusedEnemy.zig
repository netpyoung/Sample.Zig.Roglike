const std = @import("std");
const Engine = @import("../Engine.zig");
const Entity = @import("../entities/Entity.zig");

const Action = @import("../actions/Action.zig").Action;
const MeleeAction = @import("../actions/MeleeAction.zig");
const WaitAction = @import("../actions/WaitAction.zig");
const MovementAction = @import("../actions/MovementAction.zig");

const int2 = @import("../int2.zig");
const GameMap = @import("../MapObjects/GameMap.zig");
const c = @import("../c.zig").c;

// BaseAI
const AI_ConfusedEnemy = @This();

pub fn perform(self: *AI_ConfusedEnemy, allocator: std.mem.Allocator, engine: *Engine, entity: *Entity) !void {
    _ = self;
    _ = allocator;
    _ = engine;
    _ = entity;
}

pub fn deinit(self: *AI_ConfusedEnemy) void {
    _ = self;
}
