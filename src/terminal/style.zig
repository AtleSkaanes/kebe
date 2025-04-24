const std = @import("std");

const cursor = @import("./cursor.zig");

pub const ToAnsiErr = error{
    BufTooSmall,
};

pub const Color = union(enum) {
    const Self = @This();

    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    default,

    brightBlack,
    brightRed,
    brightGreen,
    brightYellow,
    brightBlue,
    brightMagenta,
    brightCyan,
    brightWhite,

    rgb: struct { r: u8, g: u8, b: u8 },

    pub fn fgAnsiCodePart(self: Self, buf: []u8) ToAnsiErr!usize {
        const str: []const u8 = switch (self) {
            .black => "30",
            .red => "31",
            .green => "32",
            .yellow => "33",
            .blue => "34",
            .magenta => "35",
            .cyan => "36",
            .white => "37",
            .default => "39",

            .brightBlack => "90",
            .brightRed => "91",
            .brightGreen => "92",
            .brightYellow => "93",
            .brightBlue => "94",
            .brightMagenta => "95",
            .brightCyan => "96",
            .brightWhite => "97",

            .rgb => |col| blk: {
                var print_buf: [16]u8 = undefined;
                const code = std.fmt.bufPrint(&print_buf, "38;2;{};{};{}", .{ col.r, col.g, col.b }) catch unreachable;
                break :blk code;
            },
        };

        if (buf.len < str.len) {
            return error.BufTooSmall;
        }

        @memcpy(buf[0..str.len], str);
        return str.len;
    }

    pub fn bgAnsiCodePart(self: Self, buf: []u8) ToAnsiErr!usize {
        const str: []const u8 = switch (self) {
            .black => "40",
            .red => "41",
            .green => "42",
            .yellow => "43",
            .blue => "44",
            .magenta => "45",
            .cyan => "46",
            .white => "47",
            .default => "49",

            .brightBlack => "100",
            .brightRed => "101",
            .brightGreen => "102",
            .brightYellow => "103",
            .brightBlue => "104",
            .brightMagenta => "105",
            .brightCyan => "106",
            .brightWhite => "107",

            .rgb => |col| blk: {
                var print_buf: [16]u8 = undefined;
                const code = std.fmt.bufPrint(&print_buf, "48;2;{};{};{}", .{ col.r, col.g, col.b }) catch unreachable;
                break :blk code;
            },
        };

        if (buf.len < str.len) {
            return error.BufTooSmall;
        }

        @memcpy(buf[0..str.len], str);
        return str.len;
    }
};

pub const Modif = enum {
    const Self = @This();

    bold,
    faint,
    italic,
    underline,
    blinking,
    inverse,
    hidden,
    strikethrough,

    pub fn startAnsiCodePart(self: Self) u8 {
        return switch (self) {
            .bold => '1',
            .faint => '2',
            .italic => '3',
            .underline => '4',
            .blinking => '5',
            .inverse => '7',
            .hidden => '8',
            .strikethrough => '9',
        };
    }

    pub fn endAnsiCodePart(self: Self) [2]u8 {
        return switch (self) {
            .bold => .{ '2', '2' },
            .faint => .{ '2', '2' },
            .italic => .{ '2', '3' },
            .underline => .{ '2', '4' },
            .blinking => .{ '2', '5' },
            .inverse => .{ '2', '7' },
            .hidden => .{ '2', '8' },
            .strikethrough => .{ '2', '9' },
        };
    }
};

pub const Style = struct {
    fg: Color = .default,
    bg: Color = .default,
    modifs: []const Modif = &.{},
};

pub const StyledStr = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    inner_str: []u8,
    style: Style,

    pub fn init(allocator: std.mem.Allocator, str: []const u8, style: Style) std.mem.Allocator.Error!Self {
        return Self{
            .allocator = allocator,
            .inner_str = try allocator.dupe(u8, str),
            .style = Style{
                .fg = style.fg,
                .bg = style.bg,
                .modifs = try allocator.dupe(Modif, style.modifs),
            },
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.inner_str);
        self.allocator.free(self.style.modifs);
    }

    pub fn allocStr(self: Self) std.mem.Allocator.Error![]u8 {
        var front_sb = std.ArrayList(u8).init(self.allocator);
        defer front_sb.deinit();

        var back_sb = std.ArrayList(u8).init(self.allocator);
        defer back_sb.deinit();

        // If no style
        if (self.style.fg == .default and self.style.bg == .default and self.style.modifs.len == 0) {
            return self.allocator.dupe(u8, self.inner_str);
        }

        try front_sb.appendSlice("\x1b[");
        try back_sb.appendSlice("\x1b[");

        if (self.style.fg != .default) {
            const default: Color = .default;

            var buf: [16]u8 = undefined;
            var len = self.style.fg.fgAnsiCodePart(&buf) catch unreachable;
            try front_sb.appendSlice(buf[0..len]);
            try front_sb.append(';');

            len = default.fgAnsiCodePart(&buf) catch unreachable;
            try back_sb.appendSlice(buf[0..len]);
            try back_sb.append(';');
        }

        if (self.style.bg != .default) {
            const default: Color = .default;

            var buf: [16]u8 = undefined;
            var len = self.style.bg.bgAnsiCodePart(&buf) catch unreachable;
            try front_sb.appendSlice(buf[0..len]);
            try front_sb.append(';');

            len = default.bgAnsiCodePart(&buf) catch unreachable;
            try back_sb.appendSlice(buf[0..len]);
            try back_sb.append(';');
        }

        for (self.style.modifs) |modif| {
            try front_sb.append(modif.startAnsiCodePart());
            try front_sb.append(';');

            try back_sb.appendSlice(&modif.endAnsiCodePart());
            try back_sb.append(';');
        }

        // Remove last semicolon
        _ = front_sb.pop();
        _ = back_sb.pop();

        try front_sb.append('m');
        try back_sb.append('m');

        try front_sb.appendSlice(self.inner_str);
        try front_sb.appendSlice(back_sb.items);

        return front_sb.toOwnedSlice();
    }

    pub fn write_at(self: Self, col: usize, row: usize) !void {
        const alloc = std.heap.smp_allocator;

        const str = try self.allocStr();
        defer alloc.free(str);

        const pos = try cursor.getPos();

        try cursor.moveTo(col, row);
        try std.io.getStdOut().writeAll(str);

        // Reset position
        try cursor.moveTo(pos.col, pos.row);
    }

    pub fn set_fg(self: *Self, fg: Color) void {
        self.style.fg = fg;
    }

    pub fn set_bg(self: *Self, bg: Color) void {
        self.style.bg = bg;
    }

    pub fn set_modifiers(self: *Self, modifs: []const Modif) std.mem.Allocator.Error!void {
        self.style.modifs = try self.allocator.dupe(Modif, modifs);
    }
};

test "style string" {
    try std.testing.expect(false);

    const alloc = std.testing.allocator;

    const styled = try StyledStr.init(
        alloc,
        "hello",
        .{
            .fg = .red,
            .bg = .yellow,
            .modifs = &.{ .bold, .italic },
        },
    );
    defer styled.deinit();

    const str = try styled.allocStr();
    defer alloc.free(str);

    const expected: []const u8 = "\x1b[31;43;1mhello\x1b[39;49;22m";

    try std.testing.expect(std.mem.eql(u8, str, expected));
}
