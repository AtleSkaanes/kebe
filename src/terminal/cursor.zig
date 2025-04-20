const std = @import("std");

const stdout = std.io.getStdOut().writer();

pub const Error = @TypeOf(stdout).Error;

pub fn resetPos() Error!void {
    try stdout.writeAll("\x1b[H");
}

pub fn moveTo(line: usize, col: usize) Error!void {
    try stdout.print("\x1b[{};{}H", line, col);
}

pub fn moveUp(times: usize) Error!void {
    try stdout.print("\x1b[{}A", .{times});
}

pub fn moveDown(times: usize) Error!void {
    try stdout.print("\x1b[{}B", .{times});
}

pub fn moveRight(times: usize) Error!void {
    try stdout.print("\x1b[{}C", .{times});
}

pub fn moveLeft(times: usize) Error!void {
    try stdout.print("\x1b[{}D", .{times});
}

pub fn savePos() Error!void {
    try stdout.writeAll("\x1b[s");
}

pub fn restorePos() Error!void {
    try stdout.writeAll("\x1b[u");
}

pub fn hide() Error!void {
    try stdout.writeAll("\x1b[?25l");
}

pub fn show() Error!void {
    try stdout.writeAll("\x1b[?25h");
}

//  TODO: ADD REST OF CURSOR COMMANDS:
// - ESC[#E    moves cursor to beginning of next line, # lines down
// - ESC[#F    moves cursor to beginning of previous line, # lines up
// - ESC[#G    moves cursor to column #
// - ESC[6n    request cursor position (reports as ESC[#;#R)
// - ESC M     moves cursor one line up, scrolling if needed
