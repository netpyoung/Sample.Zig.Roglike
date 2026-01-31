const std = @import("std");
const builtin = @import("builtin");
const StateMachine = @import("State/StateMachine.zig");

const int2 = @import("int2.zig");
const Input = @import("Input.zig");
const c = @import("TCOD/c.zig").c;
const Console = @import("TCOD/Console.zig");
const Map = @import("Map/Map.zig");
const MessageLog = @import("MessageLog.zig");
const Player = @import("GameObject/Player.zig");
const Monster = @import("GameObject/Monster.zig");
const Item = @import("GameObject/Item.zig");

const Const = @import("Const.zig");
const SeedRandom = @import("SeedRandom.zig");
const Popup = @import("Popup/Popup.zig");
const Selection = @import("Selection/Selection.zig");

const AI = @import("GameObject/Components/AI/AI.zig").AI;
const AI_HostileEnemy = @import("GameObject/Components/AI/AI_HostileEnemy.zig");

const Game = @This();
random: SeedRandom = SeedRandom.Init(0),
allocator: std.mem.Allocator,
is_quit: bool,
tcod: TCodContainer,
sm: StateMachine,
map: Map,
messageLog: MessageLog,
player: Player,
monsters: std.SegmentedList(Monster, 32),
items: std.ArrayList(Item),
popup: Popup,
selection: Selection,
input: Input = .{},
_mousePosition: int2 = int2.zero,

pub fn Init(game: *Game) !void {
    const window_width = 80;
    const window_height = 50;

    const map_width = 80;
    const map_height = 43;
    const allocator = init_allocator();

    game.* = .{
        .tcod = try TCodContainer.Init(window_width, window_height),
        .allocator = allocator,
        .sm = StateMachine.Init(game),
        .map = Map.Init(allocator, map_width, map_height),
        .messageLog = .{ .allocator = allocator },
        .is_quit = false,
        .player = Const.PLAYER,
        .monsters = .{},
        .items = std.ArrayList(Item).empty,
        .popup = .{ ._game = game },
        .selection = .{ ._game = game },
    };
    game.StartNewGame();
    game.sm.SetNextState(StateMachine.State{ .inGame = .{} });
    //game.player.Pickup(allocator, &Const.CONFUSION_SCROLL);
    //game.player.Pickup(allocator, &Const.CONFUSION_SCROLL);
    //game.player.Pickup(allocator, &Const.CONFUSION_SCROLL);
    //game.popup.ShowInventoryUse();
}

pub fn Deinit(self: *Game) void {
    self.messageLog.Deinit();
    self.tcod.Deinit();
    var miter = self.monsters.iterator(0);
    while (miter.next()) |m| {
        m.Deinit();
    }
    self.monsters.deinit(self.allocator);
    self.items.deinit(self.allocator);
    self.map.Deinit(self.allocator);
    self.player.Deinit(self.allocator);
    deinit_allocator();
}

pub fn IsRunning(self: *Game) bool {
    if (self.is_quit) {
        return false;
    }
    return self.tcod.IsRunning();
}

pub fn Update(self: *Game) void {
    self.input.BeginFrame();

    var sdl_event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&sdl_event)) {
        _ = c.TCOD_context_convert_event_coordinates(self.tcod.context, &sdl_event);
        switch (sdl_event.type) {
            c.SDL_EVENT_QUIT => {
                self.is_quit = true;
                return;
            },
            else => {},
        }
        self.input.ProcessEvent(&sdl_event);
    }

    self.sm.Update();

    if (self.sm.IsNeedToChangeState()) {
        self.sm.ChangeToNextState();
    }
}

pub fn Render(self: *Game) void {
    self.tcod.console.Clear();
    self.sm.Render();
    self.tcod.ContextPresent();
}

pub fn StartNewGame(self: *Game) void {
    self.NewDungeon();
    self.messageLog.AddMessage("Hello and welcome, adventurer, to yet another dungeon!", Const.Color.WELCOME_TEXT, true);
}

fn NewDungeon(self: *Game) void {
    self.map.NewDungeon(self.allocator, &self.random);

    self._PlaceMonsters();
    self._PlaceItems();

    const lastRoom = &self.map.rooms.items[self.map.rooms.items.len - 1];
    self.player.SetPos(lastRoom.center());

    self.map.UpdateFOV(self.player.GetPos(), &self.tcod.console);
}

pub fn GetNamesAtMouseLocation(game: *const Game, buf: []u8) [:0]const u8 {
    const mp = game._mousePosition;

    const idx = @as(usize, @intCast(mp.y)) * game.map.width + @as(usize, @intCast(mp.x));
    if (idx >= game.map.arr_visible.len) {
        return "";
    }
    if (!game.map.arr_visible[idx]) {
        return "";
    }

    var names_list = std.ArrayList([]const u8).empty;
    defer names_list.deinit(game.allocator);

    if (game.player._tileComponent.pos.equal(mp)) {
        names_list.append(game.allocator, game.player._tileComponent.name) catch unreachable;
    }

    for (game.items.items) |*x| {
        if (x._tileComponent.pos.equal(mp)) {
            names_list.append(game.allocator, x._tileComponent.name) catch unreachable;
        }
    }

    var miter = game.monsters.constIterator(0);
    while (miter.next()) |x| {
        if (x._tileComponent.pos.equal(mp)) {
            names_list.append(game.allocator, x._tileComponent.name) catch unreachable;
        }
    }

    if (names_list.items.len == 0) {
        return "";
    }

    var fba = std.heap.FixedBufferAllocator.init(buf);
    const allocator = fba.allocator();
    const joined = std.mem.joinZ(allocator, ", ", names_list.items) catch unreachable;

    if (joined.len > 0) {
        joined[0] = std.ascii.toUpper(joined[0]);
    }

    return joined;
}

pub fn PerformMonstersAI(self: *Game) void {
    var miter = self.monsters.iterator(0);
    while (miter.next()) |m| {
        if (!m.IsAlive()) {
            continue;
        }

        if (m._aiOrNull == null) {
            continue;
        }

        m._aiOrNull.?.Perform();
    }
}

pub fn Action_MonsterAttack(self: *Game, attacker: *Monster) void {
    var target = &self.player;

    const damageAmount = @max(0, attacker._status._power - target._status._defence);
    const leftHP = target.AddDamange(damageAmount);

    // effect
    if (damageAmount == 0) {
        var buf: [100]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "{f} attacks {f} but does no damage", .{ attacker, target }) catch unreachable;
        self.messageLog.AddMessage(msg, Const.Color.ATK_PLAYER, true);
    } else {
        var buf: [100]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "{f} attacks {f} for {d} hit points", .{ attacker, target, damageAmount }) catch unreachable;
        self.messageLog.AddMessage(msg, Const.Color.ATK_PLAYER, true);
        if (leftHP == 0) {
            const msg2 = std.fmt.bufPrint(&buf, "{f} is dead!", .{target}) catch unreachable;
            self.messageLog.AddMessage(msg2, Const.Color.DIE_ENEMY, true);
        }
    }
}

pub fn Action_MoveOrMeleeAttack(self: *Game, addp: int2) void {
    const attacker: *const Player = &self.player;
    const nextp = attacker.GetPos().add(addp);

    var miter = self.monsters.iterator(0);
    while (miter.next()) |target| {
        if (!target.IsAlive()) {
            continue;
        }

        if (int2.equal(target._tileComponent.pos, nextp)) {
            if (target._tileComponent.blocks_movement) {
                const damageAmount = @max(0, attacker._status._power - target._status._defence);
                const leftHP = target.AddDamange(damageAmount);

                // effect
                if (damageAmount == 0) {
                    var buf: [100]u8 = undefined;
                    const msg = std.fmt.bufPrint(&buf, "{f} attacks {f} but does no damage", .{ attacker, target }) catch unreachable;
                    self.messageLog.AddMessage(msg, Const.Color.ATK_PLAYER, true);
                } else {
                    var buf: [100]u8 = undefined;
                    const msg = std.fmt.bufPrint(&buf, "{f} attacks {f} for {d} hit points", .{ attacker, target, damageAmount }) catch unreachable;
                    self.messageLog.AddMessage(msg, Const.Color.ATK_PLAYER, true);
                    if (leftHP == 0) {
                        const msg2 = std.fmt.bufPrint(&buf, "{f} is dead!", .{target}) catch unreachable;
                        self.messageLog.AddMessage(msg2, Const.Color.DIE_ENEMY, true);
                    }
                }
                return;
            }
        }
    }

    const mapMoveable = self.map.IsMoveable(nextp);
    var isMoveable = mapMoveable;

    miter = self.monsters.iterator(0);
    while (miter.next()) |x| {
        if (!x._tileComponent.blocks_movement) {
            continue;
        }
        if (int2.equal(x._tileComponent.pos, nextp)) {
            isMoveable = false;
        }
    }
    for (self.items.items) |*x| {
        if (!x._tileComponent.blocks_movement) {
            continue;
        }
        if (int2.equal(x._tileComponent.pos, nextp)) {
            isMoveable = false;
        }
    }
    if (!isMoveable) {
        // effect
        self.messageLog.AddMessage("That way is blocked.", Const.Color.DIE_ENEMY, true);
        return;
    }

    self.player.SetPos(nextp);
}

pub fn Action_ShowHistory(self: *Game) void {
    self.popup.ShowHistory();
}

pub fn Action_Pickup(self: *Game) void {
    if (self.player._inventory.IsFulled()) {
        // effect
        self.messageLog.AddMessage("Your inventory is full", Const.Color.DIE_ENEMY, true);
        return;
    }

    var buf: [64]u8 = undefined;
    const p = self.player.GetPos();
    for (0.., self.items.items) |i, *item| {
        if (!int2.equal(item.GetPos(), p)) {
            continue;
        }

        self.player.Pickup(self.allocator, item);
        _ = self.items.swapRemove(i);

        // effect
        const msg = std.fmt.bufPrint(&buf, "You picked up the {s}!", .{item._tileComponent.name}) catch unreachable;
        self.messageLog.AddMessage(msg, c.TCOD_white, true);
        break;
    }

    // effect
    self.messageLog.AddMessage("There is nothing here to pick up", Const.Color.DIE_ENEMY, true);
}

pub fn Action_InventoryOpen(self: *Game) void {
    self.popup.ShowInventoryUse();
}

pub fn Action_InventoryDrop(self: *Game) void {
    self.popup.ShowInventoryDrop();
}

pub fn Action_CharacterScreen(self: *Game) void {
    self.popup.ShowCharacterScreen();
}

pub fn Action_Look(self: *Game) void {
    self.selection.Lookup();
}

pub fn Action_UseItem(self: *Game, item: *const Item) void {
    item.Activate(self);
    self.player._inventory.Remove(item);
}

pub fn Action_RemoveItem(self: *Game, item: *const Item) void {
    self.player._inventory.Remove(item);
}
// ========

fn _PlaceMonsters(self: *Game) void {
    const max_monsters_per_room = 2;
    for (0.., self.map.rooms.items) |i, room| {
        if (i == self.map.rooms.items.len - 1) {
            break;
        }

        const number_of_monsters = self.random.NextUsize(0, max_monsters_per_room + 1);

        for (0..number_of_monsters) |_| {
            const x = self.random.NextUsize(room.x1 + 1, room.x2 - 1);
            const y = self.random.NextUsize(room.y1 + 1, room.y2 - 1);
            const newp = int2.init(@intCast(x), @intCast(y));

            var isPossibleGen = true;

            var miter = self.monsters.constIterator(0);
            while (miter.next()) |m| {
                if (int2.equal(m.GetPos(), newp)) {
                    isPossibleGen = false;
                    break;
                }
            }

            if (!isPossibleGen) {
                continue;
            }

            const perc = self.random.NextPerc();
            if (perc < 0.8) {
                var newm = self.monsters.addOne(self.allocator) catch unreachable;
                newm.* = Const.ORC;
                newm.SetPos(newp);
                newm._aiOrNull = .{ .hostileEnemy = AI_HostileEnemy.Init(self, newm) };
            } else {
                var newm = self.monsters.addOne(self.allocator) catch unreachable;
                newm.* = Const.TROLL;
                newm.SetPos(newp);
                newm._aiOrNull = .{ .hostileEnemy = AI_HostileEnemy.Init(self, newm) };
            }
        }
    }
}

fn _PlaceItems(self: *Game) void {
    const max_items_per_room = 2;

    for (0.., self.map.rooms.items) |i, room| {
        if (i == self.map.rooms.items.len - 1) {
            break;
        }

        const number_of_items = self.random.NextUsize(0, max_items_per_room + 1);

        for (0..number_of_items) |_| {
            const x = self.random.NextUsize(room.x1 + 1, room.x2 - 1);
            const y = self.random.NextUsize(room.y1 + 1, room.y2 - 1);
            const newp = int2.init(@intCast(x), @intCast(y));

            var isPossibleGen = true;
            for (self.items.items) |*m| {
                if (int2.equal(m.GetPos(), newp)) {
                    isPossibleGen = false;
                    break;
                }
            }

            if (!isPossibleGen) {
                continue;
            }

            const perc = self.random.NextPerc();
            if (perc < 0.7) {
                var newi = Const.HEALING_POTION;
                newi.SetPos(newp);
                self.items.append(self.allocator, newi) catch unreachable;
            } else if (perc < 0.8) {
                var newi = Const.FIREBALL_SCROLL;
                newi.SetPos(newp);
                self.items.append(self.allocator, newi) catch unreachable;
            } else if (perc < 0.9) {
                var newi = Const.CONFUSION_SCROLL;
                newi.SetPos(newp);
                self.items.append(self.allocator, newi) catch unreachable;
            } else {
                var newi = Const.LIGHTING_SCROLL;
                newi.SetPos(newp);
                self.items.append(self.allocator, newi) catch unreachable;
            }
        }
    }
}

// ===============================================================================
// ===============================================================================

var gpa_instance = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
    // .never_unmap = true,
    // .retain_metadata = true,
    .stack_trace_frames = 16,
}){};

fn init_allocator() std.mem.Allocator {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        return gpa_instance.allocator();
    } else {
        return std.heap.page_allocator;
    }
}

fn deinit_allocator() void {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        const leaked = gpa_instance.deinit();
        if (leaked == .leak) {
            std.debug.print("\nMemory leak detected!\n", .{});
            @breakpoint();
        }
    }
}

// ========

const TCodContainer = struct {
    tileset: [*c]c.TCOD_Tileset,
    console: Console,
    context: [*c]c.TCOD_Context,
    menu_background: [*c]c.TCOD_Image,

    const ERR = error{ErrorTCodContainer};

    pub fn Init(w: i32, h: i32) !TCodContainer {
        c.TCOD_sys_set_fps(20);

        const title = "Hello World";

        const tileset = c.TCOD_tileset_load(
            "dejavu10x10_gs_tc.png",
            32,
            8,
            256,
            @as([*c]const c_int, &c.TCOD_CHARMAP_TCOD),
        );
        errdefer c.TCOD_tileset_delete(tileset);

        const console = Console.Init(w, h);
        errdefer console.Deinit();

        var param = c.TCOD_ContextParams{
            .console = console.console,
            .window_title = title,
            .renderer_type = c.TCOD_RENDERER_SDL2,
            .tileset = tileset,
        };
        var context: [*c]c.TCOD_Context = undefined;
        const err: c.TCOD_Error = c.TCOD_context_new(&param, &context);
        if (err != c.TCOD_E_OK) {
            return ERR.ErrorTCodContainer;
        }

        const menu_background = c.TCOD_image_load("menu_background.png");
        return .{
            .tileset = tileset,
            .console = console,
            .context = context,
            .menu_background = menu_background,
        };
    }

    pub fn Deinit(self: *TCodContainer) void {
        c.TCOD_image_delete(self.menu_background);
        c.TCOD_context_delete(self.context);
        self.console.Deinit();
        c.TCOD_tileset_delete(self.tileset);
    }

    pub fn IsRunning(_: *TCodContainer) bool {
        return !c.TCOD_console_is_window_closed();
    }

    pub fn ContextPresent(self: *TCodContainer) void {
        _ = c.TCOD_context_present(self.context, self.console.console, null);
    }
};
