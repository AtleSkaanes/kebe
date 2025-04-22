const std = @import("std");
const termios = std.posix.termios;

const Mutex = std.Thread.Mutex;

fn stdout() std.fs.File {
    return std.io.getStdOut();
}

const Error = @import("./term.zig").Error;

// For multithread safety
const TermiosMutex = struct {
    const Self = @This();

    mutex: Mutex = .{},
    temios: ?termios = null,

    pub fn lock(self: *Self) *?termios {
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

    var ios: termios = std.posix.tcgetattr(stdout().handle) catch return error.GetModeError;

    if (original_termios.* == null)
        original_termios.* = ios;

    makeTermiosRaw(&ios);

    std.posix.tcsetattr(stdout().handle, .FLUSH, ios) catch return error.SetModeError;
}

pub fn disableRawmode() Error!void {
    const original_termios = original_termios_mutex.lock();
    defer original_termios_mutex.unlock();

    if (original_termios.*) |ios| {
        std.posix.tcsetattr(stdout().handle, .FLUSH, ios) catch return error.SetModeError;
    }
}

fn makeTermiosRaw(ios: *termios) void {
    // From termios(3)
    // termios_p->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
    //     | INLCR | IGNCR | ICRNL | IXON);
    // termios_p->c_oflag &= ~OPOST;
    // termios_p->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
    // termios_p->c_cflag &= ~(CSIZE | PARENB);
    // termios_p->c_cflag |= CS8;

    ios.iflag.IGNBRK = false;
    ios.iflag.BRKINT = false;
    ios.iflag.PARMRK = false;
    ios.iflag.ISTRIP = false;
    ios.iflag.INLCR = false;
    ios.iflag.IGNCR = false;
    ios.iflag.ICRNL = false;
    ios.iflag.IXON = false;

    ios.oflag.OPOST = false;

    ios.lflag.ECHO = false;
    ios.lflag.ECHONL = false;
    ios.lflag.ICANON = false;
    ios.lflag.ISIG = false;
    ios.lflag.IEXTEN = false;

    ios.cflag.CSIZE = .CS8;
    ios.cflag.PARENB = false;
}
