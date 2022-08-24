//! The PlayStation's BIOS serves a greater role than a typical BIOS. It manages the CD-ROM
//! (or, would), filesystem operations (reading from the CD-ROM and memory cards), thread
//! coordination, and provides a C standard library.
//!
//! In hardware, accesses to the BIOS are quite slow because it's connected to the CPU through
//! an 8-bit bus, so the C standard library (which is used far more than everything else the BIOS
//! manages), referred to as the "kernel", is wrapped up into a bundle and copied to a dedicated
//! 64KB region of working ram.
const std = @import("std");
const log = @import("log.zig");

pub const BiosError = error {
    WrongSize,
    BadSignature,
};

/// The size of the (memory region allocated to the) BIOS, in bytes.
///
/// 512 x 1024 = 524288 = 512KiB.
pub const bios_size: u32 = 512 * 1024;

/// Takes a file path and returns the read bytes, checking if the BIOS image is valid (roughly).
pub fn loadBios(imagePath: []const u8) ![bios_size]u8 {
    var bios_data: [bios_size]u8 = undefined;
    var file = try std.fs.cwd().openFile(imagePath, .{});
    defer file.close();

    // BIOS images are always exactly `bios_size`
    if ((try file.read(&bios_data)) != bios_size) {
        return BiosError.WrongSize;
    }

    try validateBios(&bios_data);

    return bios_data;
}

/// This function sanity-checks a given binary file by checking for a few strings common to all
/// revisions of the PS1's BIOS.
///
/// Near the start of the BIOS is the text:
/// ```
///   Sony Computer Entertainment Inc.
///   <revision> by <initials>
/// ```
///
/// - I'm not sure what <revision> refers to specifically. the <initials> always ends with either
///     "by S.O." or "by K.S.", but they somtimes occur in reference to the same version string
///     across different BIOS revisions.
/// - The length of the second line varies depending on the rendition because it attributes the
///     author to additional versions. Only in SCPH-7000 is the string padded to the length of
///     later renditions with four spaces.
/// - In BIOS revisions used on the PlayStation 2, the second line is changed to
///     "PS compatible mode by M.T."
///
/// Similarly, near the end of the BIOS image is the text:
/// ```
///   System ROM Version <version> <date> <region>
///   Copyright <year/s> (C) Sony Computer Entertainment Inc.
/// ```
///
/// - <version> is between 1.1 (SCPH-3000) and 5.0 (SCPH-18000 and SCPH-30003) (or 4.5 (SCPH-101 and
///     SCPH-102B) if you consider PS2 revisions cheating)
/// - <region> may be A, J, or E, for America, Japan, and Europe respectively.
///
/// There are three exceptions:
///     - SCPH-1000 doesn't contain these strings at all
///     - The region tag is missing on the SCPH-3000's BIOS
///     - Supposedly SCPH-10000 (used in the PlayStation 2) reports "T" as its region.
pub fn validateBios(bios: []u8) !void {
    var temp_buffer: [256]u8 = undefined;

    // Grants us readUntilDelimiter, which is pretty useful.
    var bios_fbs = std.io.fixedBufferStream(bios);
    var bios_reader = bios_fbs.reader();

    // Jump to the first signature, which always begins at 0x108.
    try bios_reader.skipBytes(0x108, .{});
    const header_copyright = try bios_reader.readUntilDelimiter(&temp_buffer, '\x00');
    if (!std.mem.eql(u8, header_copyright, "Sony Computer Entertainment Inc.")) {
        log.warn("Didn't see expected header copyright information. Got: '{s}'",
            .{ header_copyright });
    } else {
        log.info("Header copyright OK", .{});
    }

    // In most BIOS revisions there is four nulls following the first string, but in a few
    // (e.g. SCPH-1002) there is only one.
    while (true) {
        const byte = try bios_reader.readByte();
        if (byte != '\x00') {
            // Pretend we didn't read that..
            try bios_fbs.seekBy(-1);
            break;
        }
    }

    const header_attribution = try bios_reader.readUntilDelimiter(&temp_buffer, '\x00');
    log.info("Attribution: '{s}'", .{ header_attribution });

    // Skip the rest of the BIOS to the footer
    try bios_fbs.seekTo(0x7FF32);
    const version = try bios_reader.readUntilDelimiter(&temp_buffer, '\x00');
    log.info("Version: '{s}'", .{ version });

    const footer_copyright = try bios_reader.readUntilDelimiter(&temp_buffer, '\x00');
    log.info("Copyright: '{s}'", .{ footer_copyright });
}

// Runs through a selection of BIOSes in bios/ and tries to load them.
test "Loading BIOSes" {
    _ = try std.io.getStdErr().writer().print("\n", .{});

    var iterableDir = try std.fs.cwd().openIterableDir("bios", .{});
    var walker = try iterableDir.walk(std.heap.page_allocator);
    defer walker.deinit();

    while (try walker.next()) |path| {
        const fullPath = try std.fs.path.join(std.heap.page_allocator, &.{ "bios", path.path });
        if (path.kind != .File) {
            continue;
        }

        log.info("{s}", .{ fullPath });
        _ = try loadBios(fullPath);
        _ = try std.io.getStdErr().writer().print("\n", .{});
    }
}