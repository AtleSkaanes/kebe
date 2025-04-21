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

    try cursor.hide();
    defer cursor.show() catch {};

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

    for (0..20) |_| {
        std.debug.print("{s}", .{str});
        std.Thread.sleep(std.time.ns_per_s * 0.5);
        try screen.eraseCurrentLine();
        try cursor.resetPos();
        std.Thread.sleep(std.time.ns_per_s * 0.5);
    }
}
