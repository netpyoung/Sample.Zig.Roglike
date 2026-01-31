const std = @import("std");

const c = @import("TCOD/c.zig").c;
const Console = @import("TCOD/Console.zig");

const MessageLog = @This();
messages: std.ArrayList(Message) = std.ArrayList(Message).empty,
allocator: std.mem.Allocator,

pub fn Deinit(self: *MessageLog) void {
    for (self.messages.items) |message| {
        message.Deinit(self.allocator);
    }

    self.messages.deinit(self.allocator);
}

pub fn AddMessage(self: *MessageLog, text: []const u8, fg: c.TCOD_color_t, stack: bool) void {
    if (stack) {
        if (self.messages.items.len > 0) {
            if (std.mem.eql(u8, text, self.messages.items[self.messages.items.len - 1].plain_text)) {
                self.messages.items[self.messages.items.len - 1].count += 1;
                return;
            }
        }
    }

    self.messages.append(self.allocator, Message.Init(self.allocator, text, fg)) catch unreachable;
}

pub fn RenderAll(self: *MessageLog, allocator: std.mem.Allocator, console: *const Console, x: i32, y: i32, width: i32, height: i32) void {
    self.RenderMessages(allocator, console, x, y, width, height, self.messages.items);
}

pub fn RenderMessages(self: *MessageLog, allocator: std.mem.Allocator, console: *const Console, x: i32, y: i32, width: i32, height: i32, messages: []Message) void {
    _ = self;

    if (messages.len == 0) {
        return;
    }

    var y_offset: i32 = height - 1;

    var revMessage = std.mem.reverseIterator(messages);
    while (revMessage.next()) |msg| {
        var wrapped_lines = std.ArrayList([:0]const u8).empty;
        defer {
            for (wrapped_lines.items) |line| {
                allocator.free(line);
            }
            wrapped_lines.deinit(allocator);
        }

        {
            const full_text = msg.FullText(allocator);
            defer allocator.free(full_text);
            WrapText(allocator, full_text, @intCast(width), &wrapped_lines) catch unreachable;
        }

        var revWrapped = std.mem.reverseIterator(wrapped_lines.items);
        while (revWrapped.next()) |line| {
            _ = c.TCOD_printn_rgb(
                console.console,
                .{
                    .x = x,
                    .y = y + y_offset,
                    .width = width,
                    .height = height,
                    .alignment = c.TCOD_LEFT,
                    .fg = &msg.fg,
                    .bg = 0,
                    .flag = c.TCOD_BKGND_SET,
                },
                @intCast(line.len),
                line,
            );
            y_offset -= 1;
            if (y_offset < 0) {
                return;
            }
        }
    }
}

fn WrapText(allocator: std.mem.Allocator, text: []const u8, width: usize, lines: *std.ArrayList([:0]const u8)) !void {
    var start: usize = 0;

    while (start < text.len) {
        var end = @min(start + width, text.len);

        if (end < text.len and text[end] != ' ') {
            var last_space = end;
            while (last_space > start and text[last_space] != ' ') {
                last_space -= 1;
            }
            if (last_space > start) {
                end = last_space;
            }
        }

        const line = try allocator.dupeZ(u8, text[start..end]);
        try lines.append(allocator, line);

        start = end;
        while (start < text.len and text[start] == ' ') {
            start += 1;
        }
    }
}

const Message = struct {
    plain_text: []const u8,
    fg: c.TCOD_color_t,
    count: usize,

    pub fn Init(allocator: std.mem.Allocator, text: []const u8, fg: c.TCOD_color_t) Message {
        const cloned_text = allocator.dupe(u8, text) catch unreachable;
        return .{
            .plain_text = cloned_text,
            .fg = fg,
            .count = 0,
        };
    }

    pub fn Deinit(self: *const Message, allocator: std.mem.Allocator) void {
        allocator.free(self.plain_text);
    }

    pub fn FullText(self: *const Message, allocator: std.mem.Allocator) []u8 {
        if (self.count > 1) {
            const str = std.fmt.allocPrint(allocator, "{s} (x{d})", .{ self.plain_text, self.count }) catch unreachable;
            return str;
        }
        const txt = allocator.dupe(u8, self.plain_text) catch unreachable;
        return txt;
    }
};
