const std = @import("std");
pub const style = @import("terminal/style.zig");
pub const cursor = @import("terminal/cursor.zig");

test "Run Tests" {
    std.testing.refAllDecls(@This());
}
