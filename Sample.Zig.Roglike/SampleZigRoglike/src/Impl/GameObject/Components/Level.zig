const std = @import("std");

const Level = @This();

current_level: i32 = 1,
current_xp: i32 = 0,
level_up_base: i32 = 0,
level_up_factor: i32 = 150,
xp_given: i32 = 0,
experience_to_next_level: i32 = 0,