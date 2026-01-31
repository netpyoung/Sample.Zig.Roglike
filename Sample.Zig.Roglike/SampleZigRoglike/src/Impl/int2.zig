const std = @import("std");

const int2 = @This();

x: i32,
y: i32,

pub const minusone = init(-1, -1);
pub const one = init(1, 1);
pub const zero = init(0, 0);
pub const left = init(-1, 0);
pub const right = init(1, 0);
pub const up = init(0, 1);
pub const down = init(0, -1);

pub fn init(x: i32, y: i32) int2 {
    return int2{
        .x = x,
        .y = y,
    };
}

pub fn add(a: int2, b: int2) int2 {
    return int2{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}

pub fn sub(a: int2, b: int2) int2 {
    return int2{
        .x = a.x - b.x,
        .y = a.y - b.y,
    };
}

pub fn equal(a: int2, b: int2) bool {
    return std.meta.eql(a, b);
}

pub fn format(self: int2, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("{{x={d}, y={d}}}", .{ self.x, self.y });
}
