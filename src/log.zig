const std = @import("std");
const builtin = @import("builtin");

pub fn ansiColoredLevel(comptime message_level: std.log.Level) []const u8 {
    const message_level_text = message_level.asText();
    const escape_seq = "\x1b";
    const clear_color = escape_seq ++ "[0m";

    const color = switch (message_level) {
        std.log.Level.err => escape_seq ++ "[36m",
        std.log.Level.info => escape_seq ++ "[32m",
        std.log.Level.warn => escape_seq ++ "[33m",
        std.log.Level.debug => escape_seq ++ "[34m",
    };

    return color ++ message_level_text ++ clear_color;
}

fn log(
    comptime message_level: std.log.Level,
    comptime src: std.builtin.SourceLocation,
    comptime format: []const u8,
    args: anytype,
) void {
    _ = src;
    const colored_level = comptime ansiColoredLevel(message_level);
    const stderr = std.io.getStdErr().writer();
    std.debug.getStderrMutex().lock();
    defer std.debug.getStderrMutex().unlock();

    nosuspend stderr.print("[" ++ colored_level ++ "] " ++ format ++ "\n", args) catch return;
}

pub inline fn debug(comptime format: []const u8, args: anytype) void {
    const src = @src();
    log(std.log.Level.debug, src, format, args);
}

pub inline fn info(comptime format: []const u8, args: anytype) void {
    const src = @src();
    log(std.log.Level.info, src, format, args);
}

pub inline fn warn(comptime format: []const u8, args: anytype) void {
    const src = @src();
    log(std.log.Level.warn, src, format, args);
}

pub inline fn err(comptime format: []const u8, args: anytype) void {
    const src = @src();
    log(std.log.Level.err, src, format, args);
}