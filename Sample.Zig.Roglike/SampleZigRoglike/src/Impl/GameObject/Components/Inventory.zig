const std = @import("std");

const Item = @import("../Item.zig");

const Inventory = @This();
_items: std.ArrayList(Item),
_capacity: usize,

pub fn Init(capacity: usize) Inventory {
    return .{
        ._items = .empty,
        ._capacity = capacity,
    };
}

pub fn Deinit(self: *Inventory, allocator: std.mem.Allocator) void {
    self._items.deinit(allocator);
}

pub fn Add(self: *Inventory, allocator: std.mem.Allocator, item: *const Item) void {
    self._items.append(allocator, item.*) catch unreachable;
}

pub fn Remove(self: *Inventory, item: *const Item) void {
    for (0.., self._items.items) |i, *x| {
        if (x == item) {
            _ = self._items.swapRemove(i);
            return;
        }
    }

    unreachable;
}

pub fn IsFulled(self: *const Inventory) bool {
    return self._items.items.len == self._capacity;
}
