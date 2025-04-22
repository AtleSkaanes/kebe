const std = @import("std");
const style = @import("terminal/style.zig");
const cursor = @import("terminal/cursor.zig");
const screen = @import("terminal/screen.zig");
const term = @import("terminal/term.zig");

pub fn main() !void {
    const alloc = std.heap.smp_allocator;

    try screen.enterAltScreen();
    defer screen.exitAltScreen() catch {};

    try term.enableRawmode();
    defer term.disableRawmode() catch {};

    const pos = try cursor.getPos();
    defer cursor.moveTo(pos.col, pos.col) catch {};
    try cursor.resetPos();

    const styled = try style.StyledStr.init(
        alloc,
        "hello",
        .{
            .fg = .yellow,
            .bg = .red,
            .modifs = &.{ .strikethrough, .bold, .italic },
        },
    );

    defer styled.deinit();

    const str = try styled.allocStr();
    defer alloc.free(str);

    try cursor.moveTo(10, 5);
    for (0..16) |i| {
        const shape: cursor.CursorShape = @enumFromInt(i % 5 + 1);
        try cursor.setCursorShape(shape);

        try cursor.resetPos();
        std.debug.print("{s}", .{str});

        try cursor.moveTo(10, 5);
        std.Thread.sleep(std.time.ns_per_s * 0.5);

        try cursor.resetPos();
        try screen.eraseCurrentLine();

        try cursor.moveTo(10, 5);
        std.Thread.sleep(std.time.ns_per_s * 0.5);
    }
}
