const std = @import("std");
const Mutex = std.Thread.Mutex;

// const c = @cImport(@cInclude("windows.h"));
const c = struct {};

const Error = @import("./term.zig").Error;

const ConsoleModeMutex = struct {
    const Self = @This();

    mutex: Mutex = .{},
    mode: ?c.DWORD = null,

    pub fn lock(self: *Self) *?c.DWORD {
        self.mutex.lock();
        return &self.mode;
    }

    pub fn unlock(self: *Self) void {
        self.mutex.unlock();
    }
};

var original_console_mode_mutex: ConsoleModeMutex = .{};

const stdout = std.io.getStdOut();

pub fn enableRawmode() Error!void {
    const orig_console_mode = original_console_mode_mutex.lock();
    defer original_console_mode_mutex.unlock();

    var mode: c.DWORD = undefined;
    const get_result = c.GetConsoleMode(stdout.handle, &mode);
    if (get_result == 0) {
        return error.GetModeError;
    }

    if (orig_console_mode.* == null)
        orig_console_mode.* = mode;

    const set_result = c.SetConsoleMode(stdout.handle, 0);
    if (set_result == 0)
        return error.SetModeError;
}

pub fn disableRawmode() Error!void {
    const orig_console_mode = original_console_mode_mutex.lock();
    defer original_console_mode_mutex.unlock();

    if (orig_console_mode.*) |mode| {
        const set_result = c.SetConsoleMode(stdout.handle, mode);
        if (set_result == 0)
            return error.SetModeError;
    }
}
