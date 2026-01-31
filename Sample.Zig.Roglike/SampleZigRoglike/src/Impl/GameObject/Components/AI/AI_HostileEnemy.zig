const std = @import("std");

const int2 = @import("../../../int2.zig");
const Game = @import("../../../Game.zig");
const Map = @import("../../../Map/Map.zig");
const Monster = @import("../../../GameObject/Monster.zig");
const c = @import("../../../TCOD/c.zig").c;

// BaseAI
const AI_HostileEnemy = @This();
_game: *Game,
_monster: *Monster,
_path: ?Iterator_PathTo = null,

pub fn Init(game: *Game, monster: *Monster) AI_HostileEnemy {
    return .{
        ._game = game,
        ._monster = monster,
    };
}

pub fn Deinit(self: *AI_HostileEnemy) void {
    if (self._path != null) {
        self._path.?.deinit();
    }
}

pub fn Perform(self: *AI_HostileEnemy) void {
    const src = self._monster;
    const dst = &self._game.player;

    const map = &self._game.map;

    const srcp = src.GetPos();
    const dstp = dst.GetPos();

    const diffp = int2.sub(dstp, srcp);

    const idx = @as(usize, @intCast(srcp.y)) * map.width + @as(usize, @intCast(srcp.x));
    if (map.arr_visible[idx]) {
        const distance: i32 = @intCast(@max(@abs(diffp.x), @abs(diffp.y))); //  # Chebyshev distance.
        if (distance <= 1) {
            self._game.Action_MonsterAttack(self._monster);
            return;
        }

        if (self._path != null) {
            self._path.?.deinit();
        }

        self._path = Iterator_PathTo.Init(self._game, srcp, dstp);
    }

    if (self._path != null) {
        if (self._path.?.next()) |nextp| {
            self._monster.SetPos(nextp);
        }
    }
}

// =========================
const Iterator_PathTo = struct {
    const PathContext = struct {
        map: *Map,
        costs: []u32,
    };

    _game: *Game,
    _isDone: bool,
    _ctx: *PathContext,
    _path: c.TCOD_path_t,

    pub fn Init(game: *Game, srcp: int2, dstp: int2) Iterator_PathTo {
        var costs = game.allocator.alloc(u32, game.map.arr.len) catch unreachable;
        @memset(costs, 0);

        for (0..game.map.arr.len) |i| {
            if (game.map.arr[i].IsWalkable()) {
                game.tcod.console.map.*.cells[i].walkable = true;
                costs[i] = 1;
            } else {
                game.tcod.console.map.*.cells[i].walkable = false;
            }
        }

        var miter = game.monsters.constIterator(0);
        while (miter.next()) |x| {
            if (!x._tileComponent.blocks_movement) {
                continue;
            }
            const p = x.GetPos();

            const idx = @as(usize, @intCast(p.y)) * game.map.width + @as(usize, @intCast(p.x));
            if (costs[idx] != 0) {
                costs[idx] += 10;
            }
        }

        for (game.items.items) |*x| {
            if (!x._tileComponent.blocks_movement) {
                continue;
            }
            const p = x.GetPos();

            const idx = @as(usize, @intCast(p.y)) * game.map.width + @as(usize, @intCast(p.x));
            if (costs[idx] != 0) {
                costs[idx] += 10;
            }
        }

        const ctx = game.allocator.create(PathContext) catch unreachable;
        ctx.* = PathContext{
            .map = &game.map,
            .costs = costs,
        };

        const path = c.TCOD_path_new_using_function(
            @intCast(game.map.width),
            @intCast(game.map.height),
            GetPathCost,
            ctx,
            1.414,
        );

        const src_x = srcp.x;
        const src_y = srcp.y;
        const dst_x = dstp.x;
        const dst_y = dstp.y;
        const isSuccess = c.TCOD_path_compute(path, src_x, src_y, dst_x, dst_y);

        const ret = Iterator_PathTo{
            ._game = game,
            ._isDone = !isSuccess,
            ._path = path,
            ._ctx = ctx,
        };

        return ret;
    }

    pub fn deinit(self: *Iterator_PathTo) void {
        c.TCOD_path_delete(self._path);
        self._game.allocator.free(self._ctx.costs);
        self._game.allocator.destroy(self._ctx);
    }

    fn GetPathCost(x1: i32, y1: i32, x2: i32, y2: i32, user_data: ?*anyopaque) callconv(.c) f32 {
        const ctx: *const PathContext = @ptrCast(@alignCast(user_data.?));

        if (x2 < 0 or x2 >= ctx.map.width) {
            return 0.0;
        }

        if (y2 < 0 or y2 >= ctx.map.height) {
            return 0.0;
        }

        const ux2: usize = @intCast(x2);
        const uy2: usize = @intCast(y2);

        const base_cost = @as(f32, @floatFromInt(ctx.costs[uy2 * ctx.map.width + ux2]));
        if (base_cost == 0) {
            return 0.0;
        }

        const is_diagonal = (x1 != x2 and y1 != y2);
        if (is_diagonal) {
            return base_cost * 1.5;
        }
        return base_cost;
    }

    pub fn next(self: *Iterator_PathTo) ?int2 {
        if (self._isDone) {
            return null;
        }
        if (c.TCOD_path_is_empty(self._path)) {
            return null;
        }

        var next_x: i32 = 0;
        var next_y: i32 = 0;
        while (c.TCOD_path_walk(self._path, &next_x, &next_y, true)) {
            return int2.init(next_x, next_y);
        }
        self._isDone = true;
        return null;
    }
};
