// Code inspired by ztui-tabby: https://github.com/Calder-Ty/ztui/blob/master/ztui-tabby/terminal.zig

const std = @import("std");
const builtin = @import("builtin");

const Inner = if (builtin.target.os.tag == .windows) @import("./term_windows.zig") else @import("./term_posix.zig");

pub const Error = error{
    GetModeError,
    SetModeError,
};

pub const enableRawmode = Inner.enableRawmode;
pub const disableRawmode = Inner.disableRawmode;
