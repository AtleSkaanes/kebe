const std = @import("std");

const Mutex = std.Thread.Mutex;

const c = @cImport(@cInclude("termios.h"));
const stdout = std.io.getStdOut();

const Error = @import("./term.zig").Error;

// For multithread safety
const TermiosMutex = struct {
    const Self = @This();

    mutex: Mutex = .{},
    temios: ?c.termios = null,

    pub fn lock(self: *Self) *?c.termios {
        self.mutex.lock();
        return &self.temios;
    }

    pub fn unlock(self: *Self) void {
        self.mutex.unlock();
    }
};

var original_termios_mutex: TermiosMutex = .{};

pub fn enableRawmode() Error!void {
    const original_termios = original_termios_mutex.lock();
    defer original_termios_mutex.unlock();

    var termios: c.termios = undefined;
    const get_result = c.tcgetattr(stdout.handle, &termios);
    if (get_result == -1)
        return error.GetModeError;

    if (original_termios.* == null)
        original_termios.* = termios;

    c.cfmakeraw(&termios);

    const set_result = c.tcsetattr(stdout.handle, c.TCSANOW, &termios);
    if (set_result == -1)
        return error.SetModeError;
}

pub fn disableRawmode() Error!void {
    const original_termios = original_termios_mutex.lock();
    defer original_termios_mutex.unlock();

    if (original_termios.*) |termios| {
        const set_result = c.tcsetattr(stdout.handle, c.TCSANOW, &termios);
        if (set_result == -1)
            return error.SetModeError;
    }
}
