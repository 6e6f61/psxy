//! psxy is a Sony PlayStation 1 emulator majorly written in Zig.
//! The name was chosen because it is funny. In fact, this emulator was written because the name
//! is funny.
const std = @import("std");
const accord = @import("accord");
const bios = @import("bios.zig");
const Cpu = @import("cpu.zig").Cpu;
const log = @import("log.zig");

const help =
\\psxy: PlayStation 1 Emulator
\\Usage: psxy [options] rom
\\Options:
\\  -h, --help    display this help
\\      --bios    select the path of the BIOS to load [default: bios.bin]
;

pub fn main() !void {
    // Argument parsing stuff
    var argv = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer argv.deinit();
    const args = try accord.parse(&.{
        accord.option('h', "help", accord.Flag, {}, .{}),
        accord.option(0, "bios", []const u8, "bios.bin", .{}),
    }, std.heap.page_allocator, &argv);
    defer args.positionals.deinit(std.heap.page_allocator);

    if (args.help) {
        try std.io.getStdOut().writer().print(help, .{});
        return;
    }

    var cpu = Cpu.init();
    const loaded_bios = try bios.loadBios(args.bios);
    cpu.memory.setBios(loaded_bios);

    while (true) {
        try cpu.cycle();
        cpu.dumpState();
    }
}