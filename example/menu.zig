const std = @import("std");
const heap = std.heap;
const math = std.math;
const mem = std.mem;
const os = std.posix.system;

const spoon = @import("spoon");

var term: spoon.Term = undefined;
var loop: bool = true;

var cursor: usize = 0;

pub fn main() !void {
    try term.init(.{});
    defer term.deinit() catch {};

    std.posix.sigaction(os.SIG.WINCH, &os.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = os.empty_sigset,
        .flags = 0,
    }, null);

    var fds: [1]os.pollfd = undefined;
    fds[0] = .{
        .fd = term.tty.?,
        .events = os.POLL.IN,
        .revents = undefined,
    };

    // zig-spoon will return the terminal back to cooked state automatically
    // when we call term.deinit().
    try term.uncook(.{});

    try term.fetchSize();
    try term.setWindowTitle("zig-spoon example: menu", .{});
    try render();

    var buf: [16]u8 = undefined;
    while (loop) {
        _ = try std.posix.poll(&fds, -1);

        const read = try term.readInput(&buf);
        var it = spoon.inputParser(buf[0..read]);
        while (it.next()) |in| {
            // The input descriptor parser is not only useful for user-configuration.
            // Since it can work at comptime, you can use it to simplify the
            // matching of hardcoded keybinds as well. Down below we specify the
            // typical keybinds a terminal user would expect for moving up and
            // down, without getting our hands dirty in the interals of zig-spoons
            // Input object.
            if (in.eqlDescription("escape") or in.eqlDescription("q")) {
                loop = false;
                break;
            } else if (in.eqlDescription("arrow-down") or in.eqlDescription("C-n") or in.eqlDescription("j")) {
                if (cursor < 3) {
                    cursor += 1;
                    try render();
                }
            } else if (in.eqlDescription("arrow-up") or in.eqlDescription("C-p") or in.eqlDescription("k")) {
                cursor -|= 1;
                try render();
            }
        }
    }
}

fn render() !void {
    var rc = try term.getRenderContext();
    defer rc.done() catch {};

    try rc.clear();

    if (term.width < 6) {
        try rc.setAttribute(.{ .fg = .red, .bold = true });
        try rc.writeAllWrapping("Terminal too small!");
        return;
    }

    try rc.moveCursorTo(0, 0);
    try rc.setAttribute(.{ .fg = .green, .reverse = true });

    // The RestrictedPaddingWriter helps us avoid writing more than the terminal
    // is wide. It exposes a normal writer interface you can use with any
    // function that integrates with that, such as print(), write() and writeAll().
    // The RestrictedPaddingWriter.pad() function will fill the remaining space
    // with whitespace padding.
    var rpw = rc.restrictedPaddingWriter(term.width);
    try rpw.writer().writeAll(" Spoon example program: menu");
    try rpw.pad();

    try rc.moveCursorTo(1, 0);
    try rc.setAttribute(.{ .fg = .red, .bold = true });
    rpw = rc.restrictedPaddingWriter(term.width);
    try rpw.writer().writeAll(" Up and Down arrows to select, q to exit.");
    try rpw.finish(); // No need to pad here, since there is no background.

    const entry_width = @min(term.width - 2, 8);
    try menuEntry(&rc, " foo", 3, entry_width);
    try menuEntry(&rc, " bar", 4, entry_width);
    try menuEntry(&rc, " baz", 5, entry_width);
    try menuEntry(&rc, " →µ←", 6, entry_width);
}

fn menuEntry(rc: *spoon.Term.RenderContext, name: []const u8, row: usize, width: usize) !void {
    try rc.moveCursorTo(row, 2);
    try rc.setAttribute(.{ .fg = .blue, .reverse = (cursor == row - 3) });
    var rpw = rc.restrictedPaddingWriter(width - 1);
    defer rpw.pad() catch {};
    try rpw.writer().writeAll(name);
}

fn handleSigWinch(_: c_int) callconv(.C) void {
    term.fetchSize() catch {};
    render() catch {};
}
