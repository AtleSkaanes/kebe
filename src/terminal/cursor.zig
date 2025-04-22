const std = @import("std");

fn stdout() std.fs.File {
    return std.io.getStdOut();
}

pub const Error = std.io.AnyWriter.Error;

pub const CursorShape = enum(u8) {
    block_blinking = 1,
    block,
    underline_blinking,
    underline,
    bar_blinking,
    bar,
};

pub fn setCursorShape(shape: CursorShape) Error!void {
    try stdout().writer().print("\x1b[{} q", .{@intFromEnum(shape)});
}

pub fn resetPos() Error!void {
    try stdout().writeAll("\x1b[H");
}

pub fn moveTo(col: usize, row: usize) Error!void {
    try stdout().writer().print("\x1b[{};{}H", .{ row, col });
}

pub fn getPos() (Error || error{ReadError})!struct { col: usize, row: usize } {
    const alloc = std.heap.smp_allocator;
    const stdin = std.io.getStdIn();

    try stdout().writeAll("\x1b[6n");
    var poller = std.io.poll(alloc, enum { stdin }, .{ .stdin = stdin });
    defer poller.deinit();

    if (poller.poll() catch return error.ReadError) {
        var buf: [64]u8 = undefined;
        const len = poller.fifo(.stdin).read(&buf);

        // std.debug.writer().print("\\x1b{s}\n", .{buf[1..len]});
        // std.debug.writer().print("col: {s}\trow: {s}", .{ buf[2..4], buf[5..6] });

        var splitter = std.mem.splitScalar(u8, buf[0..len], ';');
        const lhs = splitter.next() orelse return error.ReadError;
        const rhs = splitter.next() orelse return error.ReadError;

        // LHS needs to be ESC[# and rhs needs to be #R
        if (lhs.len < 3 or rhs.len < 2)
            return error.ReadError;

        const row_int = std.fmt.parseInt(usize, lhs[2..], 10) catch return error.ReadError;
        const col_int = std.fmt.parseInt(usize, rhs[0 .. rhs.len - 1], 10) catch return error.ReadError;

        return .{ .col = col_int, .row = row_int };
    } else {
        return error.ReadError;
    }
}

pub fn moveUp(times: usize) Error!void {
    try stdout().writer().print("\x1b[{}A", .{times});
}

pub fn moveDown(times: usize) Error!void {
    try stdout().writer().print("\x1b[{}B", .{times});
}

pub fn moveRight(times: usize) Error!void {
    try stdout().writer().print("\x1b[{}C", .{times});
}

pub fn moveLeft(times: usize) Error!void {
    try stdout().writer().print("\x1b[{}D", .{times});
}

pub fn savePos() Error!void {
    try stdout().writeAll("\x1b[s");
}

pub fn restorePos() Error!void {
    try stdout().writeAll("\x1b[u");
}

pub fn hide() Error!void {
    try stdout().writeAll("\x1b[?25l");
}

pub fn show() Error!void {
    try stdout().writeAll("\x1b[?25h");
}

//  TODO: ADD REST OF CURSOR COMMANDS:
// - ESC[#E    moves cursor to beginning of next line, # lines down
// - ESC[#F    moves cursor to beginning of previous line, # lines up
// - ESC[#G    moves cursor to column #
// - ESC M     moves cursor one line up, scrolling if needed
