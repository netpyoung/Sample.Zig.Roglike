const std = @import("std");

const c = @import("TCOD/c.zig").c;
const int2 = @import("int2.zig");

const Input = @This();
_key_now: [c.SDL_SCANCODE_COUNT]bool = [_]bool{false} ** c.SDL_SCANCODE_COUNT,
_key_prev: [c.SDL_SCANCODE_COUNT]bool = [_]bool{false} ** c.SDL_SCANCODE_COUNT,
_mousebutton_now: [@typeInfo(E_BUTTON_CODE).@"enum".fields.len]bool = [_]bool{false} ** @typeInfo(E_BUTTON_CODE).@"enum".fields.len,
_mousebutton_prev: [@typeInfo(E_BUTTON_CODE).@"enum".fields.len]bool = [_]bool{false} ** @typeInfo(E_BUTTON_CODE).@"enum".fields.len,
_mouseposition_now: int2 = int2.zero,
_mouseposition_prev: int2 = int2.zero,
_isKeydown: bool = false,
_isMouseDown: bool = false,

pub const E_KEYCODE = enum(usize) {
    LCTRL = c.SDL_SCANCODE_LCTRL,
    LSHIFT = c.SDL_SCANCODE_LSHIFT,
    LALT = c.SDL_SCANCODE_LALT,
    RCTRL = c.SDL_SCANCODE_RCTRL,
    RSHIFT = c.SDL_SCANCODE_RSHIFT,
    RALT = c.SDL_SCANCODE_RALT,

    UP = c.SDL_SCANCODE_UP,
    DOWN = c.SDL_SCANCODE_DOWN,
    LEFT = c.SDL_SCANCODE_LEFT,
    RIGHT = c.SDL_SCANCODE_RIGHT,
    PAGEUP = c.SDL_SCANCODE_PAGEUP,
    PAGEDOWN = c.SDL_SCANCODE_PAGEDOWN,

    HOME = c.SDL_SCANCODE_HOME,
    END = c.SDL_SCANCODE_END,
    RETURN = c.SDL_SCANCODE_RETURN,
    KP_ENTER = c.SDL_SCANCODE_KP_ENTER,

    ESCAPE = c.SDL_SCANCODE_ESCAPE,
    A = c.SDL_SCANCODE_A,
    B = c.SDL_SCANCODE_B,
    C = c.SDL_SCANCODE_C,
    D = c.SDL_SCANCODE_D,
    E = c.SDL_SCANCODE_E,
    F = c.SDL_SCANCODE_F,
    G = c.SDL_SCANCODE_G,
    H = c.SDL_SCANCODE_H,
    I = c.SDL_SCANCODE_I,
    J = c.SDL_SCANCODE_J,
    K = c.SDL_SCANCODE_K,
    L = c.SDL_SCANCODE_L,
    M = c.SDL_SCANCODE_M,
    N = c.SDL_SCANCODE_N,
    O = c.SDL_SCANCODE_O,
    P = c.SDL_SCANCODE_P,
    Q = c.SDL_SCANCODE_Q,
    R = c.SDL_SCANCODE_R,
    S = c.SDL_SCANCODE_S,
    T = c.SDL_SCANCODE_T,
    U = c.SDL_SCANCODE_U,
    V = c.SDL_SCANCODE_V,
    W = c.SDL_SCANCODE_W,
    X = c.SDL_SCANCODE_X,
    Y = c.SDL_SCANCODE_Y,
    Z = c.SDL_SCANCODE_Z,

    SLASH = c.SDL_SCANCODE_SLASH,

    PERIOD = c.SDL_SCANCODE_PERIOD,
    KP_5 = c.SDL_SCANCODE_KP_5,
    CLEAR = c.SDL_SCANCODE_CLEAR,
};

pub fn GetKey(self: *const Input, keycode: E_KEYCODE) bool {
    const idx = @intFromEnum(keycode);
    return self._key_now[idx];
}

pub fn GetKeyDown(self: *const Input, keycode: E_KEYCODE) bool {
    const idx = @intFromEnum(keycode);
    return self._key_now[idx] and !self._key_prev[idx];
}

pub const E_BUTTON_CODE = enum(usize) {
    LEFT = @intCast(c.SDL_BUTTON_LEFT),
    RIGHT = @intCast(c.SDL_BUTTON_MIDDLE),
    MIDDLE = @intCast(c.SDL_BUTTON_RIGHT),
};

pub fn GetMouseButtonDown(self: *const Input, btncode: E_BUTTON_CODE) bool {
    const idx = @intFromEnum(btncode);
    return self._mousebutton_now[idx] and !self._mousebutton_prev[idx];
}

pub fn GetMousePosition(self: *const Input) int2 {
    return self._mouseposition_now;
}

pub fn GetMousePositionDelta(self: *const Input) int2 {
    return int2.sub(self._mouseposition_prev, self._mouseposition_now);
}

pub fn IsAnyKeyOrMouseDown(self: *const Input) bool {
    if (self._isKeydown) {
        return true;
    }

    if (self._isMouseDown) {
        return true;
    }
    return false;
}

pub fn IsAlphaKeyDown(self: *const Input) bool {
    const a = @intFromEnum(E_KEYCODE.A);
    const z = @intFromEnum(E_KEYCODE.Z);
    for (a..z + 1) |i| {
        const e: E_KEYCODE = @enumFromInt(i);
        if (self.GetKeyDown(e)) {
            return true;
        }
    }
    return false;
}

// ==================

pub fn BeginFrame(self: *Input) void {
    self._key_prev = self._key_now;
    self._mousebutton_prev = self._mousebutton_now;
    self._mouseposition_prev = self._mouseposition_now;

    @memset(&self._key_now, false);
    @memset(&self._mousebutton_now, false);

    self._isKeydown = false;
    self._isMouseDown = false;
}

pub fn ProcessEvent(self: *Input, sdlevt: *const c.SDL_Event) void {
    switch (sdlevt.type) {
        c.SDL_EVENT_KEY_DOWN => {
            const sc = sdlevt.key.scancode;
            self._key_now[sc] = true; 

            if (!sdlevt.key.repeat) {
                self._isKeydown = true;
            }
        },
        c.SDL_EVENT_KEY_UP => {
            const sc = sdlevt.key.scancode;
            self._key_now[sc] = false;
        },
        c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
            const btn = sdlevt.button.button;
            if (btn >= self._mousebutton_now.len) {
                return;
            }
            self._mousebutton_now[btn] = true;
            self._isMouseDown = true;
        },
        c.SDL_EVENT_MOUSE_BUTTON_UP => {
            const btn = sdlevt.button.button;
            if (btn >= self._mousebutton_now.len) {
                return;
            }
            self._mousebutton_now[btn] = false;
        },
        c.SDL_EVENT_MOUSE_MOTION => {
            const mx: i32 = @intFromFloat(sdlevt.button.x);
            const my: i32 = @intFromFloat(sdlevt.button.y);
            self._mouseposition_now = int2.init(mx, my);
        },
        else => {},
    }
}
