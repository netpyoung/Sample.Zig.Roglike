const Game = @import("../Game.zig");
const State_MainMenu = @import("State_MainMenu.zig");
const State_InGame = @import("State_InGame.zig");

const StateMachine = @This();
game: *Game,
currState: State,
nextStateOrNull: ?State,

pub fn Init(game: *Game) StateMachine {
    return .{
        .game = game,
        .currState = .{
            .mainMenu = .{},
        },
        .nextStateOrNull = null,
    };
}

pub fn Update(self: *const StateMachine) void {
    self.currState.Update(self.game);
}

pub fn Render(self: *const StateMachine) void {
    self.currState.Render(self.game);
}

pub fn IsNeedToChangeState(self: *const StateMachine) bool {
    return self.nextStateOrNull != null;
}

pub fn ChangeToNextState(self: *StateMachine) void {
    self.currState = self.nextStateOrNull.?;
    self.nextStateOrNull = null;
}

pub fn SetNextState(self: *StateMachine, nextState: State) void {
    self.nextStateOrNull = nextState;
}

// ===================================================

pub const State = union(enum) {
    mainMenu: State_MainMenu,
    inGame: State_InGame,

    pub fn Update(self: *const State, game: *Game) void {
        switch (self.*) {
            inline else => |*e| e.Update(game),
        }
    }

    pub fn Render(self: *const State, game: *Game) void {
        switch (self.*) {
            inline else => |*e| e.Render(game),
        }
    }
};
