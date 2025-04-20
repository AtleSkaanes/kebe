const std = @import("std");
pub const style = @import("terminal/style.zig");

test "Run Tests" {
    std.testing.refAllDecls(@This());
}
