const c = @import("c.zig").c;

const Console = @This();
console: [*c]c.TCOD_Console,
tiles: []c.TCOD_ConsoleTile,
map: [*c]c.TCOD_Map,
width: i32,
height: i32,

pub fn Init(width: i32, height: i32) Console {
    const console = c.TCOD_console_new(width, height);
    const tiles = console.*.tiles[0..@intCast(width * height)];
    const map = c.TCOD_map_new(width, height);
    return .{
        .console = console,
        .tiles = tiles,
        .map = map,
        .width = width,
        .height = height,
    };
}

pub fn Deinit(self: *const Console) void {
    c.TCOD_map_delete(self.map);
    c.TCOD_console_delete(self.console);
}

pub fn Clear(self: *Console) void {
    c.TCOD_console_clear(self.console);
}

const TCOD_PrintParamsRGB = extern struct {
    x: c_int = 0,
    y: c_int = 0,
    width: c_int = -1,
    height: c_int = 0,
    fg: [*c]const c.TCOD_ColorRGB = &c.TCOD_white,
    bg: [*c]const c.TCOD_ColorRGB = null,
    flag: c.TCOD_bkgnd_flag_t = c.TCOD_BKGND_SET,
    alignment: c.TCOD_alignment_t = c.TCOD_LEFT,
};

pub fn Print(self: *const Console, msg: [:0]const u8, params: TCOD_PrintParamsRGB) void {
    var params2 = params;
    if (params2.width == -1) {
        switch (params2.alignment) {
            c.TCOD_LEFT => {
                params2.width = 0x100000;
            },
            c.TCOD_CENTER => {
                params2.x -= 0x100000;
                params2.width = 0x200000;
            },
            c.TCOD_RIGHT => {
                params2.x -= 0x100000;
                params2.width = 0x100000;
            },
            else => {},
        }
    }

    _ = c.TCOD_printn_rgb(self.console, @bitCast(params2), @intCast(msg.len), msg);
}

pub fn PrintBox() void {}

pub fn PrintRect(self: *const Console, msg: []const u8, params: TCOD_PrintParamsRGB) void {
    _ = c.TCOD_console_printn_rect(
        self.console,
        params.x,
        params.y,
        params.width,
        params.height,
        msg.len,
        msg.ptr,
        params.fg,
        params.bg,
        params.flag,
        params.alignment,
    );
}

pub fn DrawSemigraphics(self: *const Console, image: [*c]c.TCOD_Image) void {
    c.TCOD_image_blit_2x(image, self.console, 0, 0, 0, 0, -1, -1);
}

pub fn DrawFrame(self: *const Console, msg: []const u8, params: TCOD_PrintParamsRGB, clear: bool) void {
    _ = c.TCOD_console_printn_frame(
        self.console,
        params.x,
        params.y,
        params.width,
        params.height,
        msg.len,
        msg.ptr,
        params.fg,
        params.bg,
        params.flag,
        clear,
    );
}

pub fn PutChar(self: *const Console, x: c_int, y: c_int, cc: c_int, flag: c.TCOD_bkgnd_flag_t) void {
    c.TCOD_console_put_char(self.console, x, y, cc, flag);
}

pub fn DrawRect(
    self: *const Console,
    rect: struct { x: c_int, y: c_int, width: i32, height: i32 },
    ch: c_int,
    args: struct {
        fg: [*c]const c.TCOD_color_t = null,
        bg: [*c]const c.TCOD_color_t = null,
        flag: c.TCOD_bkgnd_flag_t = c.TCOD_BKGND_SET,
    },
) void {
    _ = c.TCOD_console_draw_rect_rgb(self.console, rect.x, rect.y, rect.width, rect.height, ch, args.fg, args.bg, args.flag);
}

pub fn Tiles(self: *const Console, x: i32, y: i32) *c.TCOD_ConsoleTile {
    const idx: usize = @intCast(y * self.width + x);
    return &self.tiles[idx];
}

// log_console.blit(console, 3, 3)

pub fn Blit(self: *const Console, xSrc: c_int, ySrc: c_int, wSrc: c_int, hSrc: c_int, noalias dst: *const Console, xDst: c_int, yDst: c_int, foreground_alpha: f32, background_alpha: f32) void {
    _ = c.TCOD_console_blit(self.console, xSrc, ySrc, wSrc, hSrc, dst.console, xDst, yDst, foreground_alpha, background_alpha);
}
