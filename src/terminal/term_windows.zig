const std = @import("std");
const Mutex = std.Thread.Mutex;

const win = std.os.windows;
const k32 = std.os.windows.kernel32;

const Error = @import("./term.zig").Error;

const Mode = struct {
    out: win.DWORD,
    in: win.DWORD,
};

const ConsoleModeMutex = struct {
    const Self = @This();

    mutex: Mutex = .{},
    mode: ?Mode = null,

    pub fn lock(self: *Self) *?Mode {
        self.mutex.lock();
        return &self.mode;
    }

    pub fn unlock(self: *Self) void {
        self.mutex.unlock();
    }
};

var original_console_mode_mutex: ConsoleModeMutex = .{};

pub fn enableRawmode() Error!void {
    // Save current console mode, to reset to on `disableRawmode()`
    const orig_console_mode = original_console_mode_mutex.lock();
    defer original_console_mode_mutex.unlock();

    const current_mode = try getMode();

    if (orig_console_mode.* == null)
        orig_console_mode.* = current_mode;

    // setting rawmode
    const raw_mode = getRawConsoleMode();

    try setMode(raw_mode);
}

pub fn disableRawmode() Error!void {
    const orig_console_mode = original_console_mode_mutex.lock();
    defer original_console_mode_mutex.unlock();

    if (orig_console_mode.*) |mode| {
        try setMode(mode);
    }
}

// Relevant console modes.
// See: https://learn.microsoft.com/en-us/windows/console/high-level-console-modes
const WINDOW_INPUT: win.DWORD = 0x0008;
const MOUSE_INPUT: win.DWORD = 0x0010;

const PROCESSED_OUTPUT: win.DWORD = 0x0001;
const VIRTUAL_TERMINAL_PROCESSING: win.DWORD = 0x0004;
const DISABLE_NEWLINE_AUTO_RETURN: win.DWORD = 0x0008;
const LVB_GRID_WORLDWIDE: win.DWORD = 0x0010;

fn getRawConsoleMode() Mode {
    const in_mode = WINDOW_INPUT | MOUSE_INPUT;

    const out_mode = PROCESSED_OUTPUT | VIRTUAL_TERMINAL_PROCESSING | DISABLE_NEWLINE_AUTO_RETURN | LVB_GRID_WORLDWIDE;

    return Mode{ .in = in_mode, .out = out_mode };
}

fn getMode() Error!Mode {
    var in_mode: win.DWORD = 0;
    const in_get_result = k32.GetConsoleMode(std.io.getStdIn().handle, &in_mode);
    if (in_get_result == 0) {
        return error.GetModeError;
    }

    var out_mode: win.DWORD = 0;
    const out_get_result = k32.GetConsoleMode(std.io.getStdOut().handle, &out_mode);
    if (out_get_result == 0) {
        return error.GetModeError;
    }

    return Mode{ .in = in_mode, .out = out_mode };
}

fn setMode(mode: Mode) Error!void {
    const in_get_result = k32.SetConsoleMode(std.io.getStdIn().handle, mode.in);
    if (in_get_result == 0) {
        return error.GetModeError;
    }

    const out_get_result = k32.SetConsoleMode(std.io.getStdOut().handle, mode.out);
    if (out_get_result == 0) {
        return error.GetModeError;
    }
}
