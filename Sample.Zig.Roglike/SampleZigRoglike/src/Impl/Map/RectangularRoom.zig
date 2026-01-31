const int2 = @import("../int2.zig");

const RectangularRoom = @This();
x1: usize,
y1: usize,
x2: usize,
y2: usize,

pub fn init(x: usize, y: usize, width: usize, height: usize) RectangularRoom {
    return .{
        .x1 = x,
        .y1 = y,
        .x2 = x + width,
        .y2 = y + height,
    };
}

pub fn center(self: *const RectangularRoom) int2 {
    const center_x: i32 = @intCast(@divTrunc(self.x1 + self.x2, 2));
    const center_y: i32 = @intCast(@divTrunc(self.y1 + self.y2, 2));

    return int2.init(center_x, center_y);
}

pub fn intersects(self: *const RectangularRoom, other: *const RectangularRoom) bool {
    // """Return True if this room overlaps with another RectangularRoom."""
    return self.x1 <= other.x2 and self.x2 >= other.x1 and
        self.y1 <= other.y2 and self.y2 >= other.y1;
}
