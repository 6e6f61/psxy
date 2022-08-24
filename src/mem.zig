//! The PlayStation utilises a logical memory system in a von Neumann architecture to address system
//! memory, cache, and IO.
//! 
//! The von Neumann computer architecture refers to designs in which code and data share a common
//! bus, a common pathway, and typically, common access (that is, code may be treated as data).
//! It differs from the Harvard architecture, in which instructions and program data is stored in
//! physically separate memory banks.
//! The PlayStation's use of the von Neumann architecture enables software executing on the
//! PlayStation to modify itself, and in some cases, patch the BIOS for various reasons.
//! Its biggest implication here is that there is only one memory bus, and that memory accesses are
//! used to manage a large portion of the system state.
//!
//! The PlayStation's 2MB of system memory is not mapped directly to a limited address range,
//! instead a larger memory space is virtualised and spread across four segments:
//!
//! Segment "Kuseg":
//! - 0x00000000 to 0x0000ffff (64KB): reserved for the kernel (see `Bios`)
//! - 0x00010000 to 0x001fffff (1.9MB): remaining physical memory
//!
//! Segment "Kseg0":
//! - 0x1f000000 to 0x1f00ffff (64KB):  parallel port R/W
//! - 0x1f800000 to 0x1f8003ff (1024B): the "scratchpad", used as a data cache.
//! - 0x1f801000 to 0x1f802fff (8K):    hardware registers
//! - 0x80000000 to 0x801fffff (2MB):   cached mirror of Kuseg
//!
//! Segment "Kseg1":
//! - 0xa0000000 to 0xa01fffff (2MB):   uncached mirror of Kuseg
//! - 0xbfc00000 to 0xbfc7ffff (512KB): BIOS
//! 
//! Segment "Kseg2":
//! - 0xfffe0000h to 0xfffe0200 (512B): I/O management.
//!
//! With this design, an application can explicitly ask for a cached or uncached copy of whatever
//! was at an address by masking the three most significant bits - these bits are always 000 when
//! that address lies in Kuseg, always 100 when it lies in Kseg0's cached mirror, and always 101
//! when it lies in Kseg1's uncached mirror. Additionally, it is such that masking these three bits
//! from 100 or 101 to 000 will result in that memory's physical address.
//!
//! This is to say addresses at 0x00xxxxxx, 0x80xxxxxx, and 0xa0xxxxxx, all point to the same
//! physical memory, while all other addresses (e.g. all of Kseg2) _don't_ point to actual memory.
//! These addresses solely exist logically and are handled specially by the CPU.
const std = @import("std");
const log = @import("log.zig");
const bios = @import("bios.zig");

/// The PlayStation's 2MB of system memory is materialised in hardware as four banks of 512KB DRAM
/// chips.
const memory_size: usize = (512 * 1024) * 4;

const physical_memory_region = Region.init(0x00, memory_size);
const bios_region            = Region.init(0xbfc00000, (1024 * 512));

/// Represents a region of logical memory.
const Region = struct {
    from: u32,
    to: u32,
    size: u32,

    fn init(from: u32, size: u32) Region {
        return Region { .from = from, .to = from + size, .size = size };
    }

    fn includes(self: Region, address: u32) bool {
        if (address >= self.from and address <= self.to) return true;
        return false;
    }

    fn relative(self: Region, address: u32) u32 {
        return address - self.from;
    }
};

const MemoryError = error {
    /// A bus error occurs when a memory address not mapped to physical space is accessed.
    Bus,
};

pub const Memory = struct {
    memory: [memory_size]u8,
    bios: [bios.bios_size]u8,

    /// The memory returned is zeroed.
    pub fn init() Memory {
        return Memory {
            .memory = std.mem.zeroes([memory_size]u8),
            .bios = undefined,
        };
    }

    pub fn setBios(self: *Memory, b: [bios.bios_size]u8) void {
        self.bios = b;
    }

    /// Returns the `WordSize` value stored at `address` in little-endian.
    pub fn load32(self: Memory, address: u32) MemoryError!u32 {
        if (physical_memory_region.includes(address)) {
            log.warn("{x} >= {x}, {x} <= {x}", .{ address, physical_memory_region.from,
                address, physical_memory_region.to });
            // If attempting to access actual working memory, we can just read from memory.
            return load32From(&self.memory, address);
        } else if (bios_region.includes(address)) {
            // Otherwise, we'll have to map the logical memory address to its appropriate
            // "component".
            const relative = bios_region.relative(address);
            return load32From(&self.bios, relative);
        }

        return MemoryError.Bus;
    }
};

// Reads four bytes from `data[offset]` and returns a u32 of its value in little-endian.
inline fn load32From(data: []const u8, offset: usize) u32 {
    // 32 bits is 4 bytes, so grab the four bytes.
    const byteOne:   u32 = data[offset];
    const byteTwo:   u32 = data[offset + 1];
    const byteThree: u32 = data[offset + 2];
    const byteFour:  u32 = data[offset + 3];

    // big endian => little endian
    // TODO: explain what endianess is
    return byteOne | (byteTwo << 8) | (byteThree << 16) | (byteFour << 24);
}