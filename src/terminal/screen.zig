const std = @import("std");

fn stdout() std.fs.File {
    return std.io.getStdOut();
}

pub const Error = std.io.AnyWriter.Error;

pub fn saveScreen() Error!void {
    try stdout().writeAll("\x1b[?47h");
}

pub fn restoreScreen() Error!void {
    try stdout().writeAll("\x1b[?47l");
}

pub fn enterAltScreen() Error!void {
    try stdout().writeAll("\x1b[?1049h");
}

pub fn exitAltScreen() Error!void {
    try stdout().writeAll("\x1b[?1049l");
}

pub fn eraseDownFromCursor() Error!void {
    try stdout().writeAll("\x1b[J");
}

pub fn eraseUpFromCursor() Error!void {
    try stdout().writeAll("\x1b[1J");
}

pub fn eraseScreen() Error!void {
    try stdout().writeAll("\x1b[2J");
}

pub fn eraseSavedLines() Error!void {
    try stdout().writeAll("\x1b[3J");
}

pub fn eraseToEndOfLine() Error!void {
    try stdout().writeAll("\x1b[K");
}

pub fn eraseToStartOfLine() Error!void {
    try stdout().writeAll("\x1b[1K");
}

pub fn eraseCurrentLine() Error!void {
    try stdout().writeAll("\x1b[2K");
}
