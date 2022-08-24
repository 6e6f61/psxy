//! The PlayStation's CPU is a MIPS Computer Systems R3000, a 32-bit RISC chipset that runs the
//! MIPS I ISA at 33.8688Mhz.
const std = @import("std");
const log = @import("log.zig");
const op = @import("op.zig");
const Memory = @import("mem.zig").Memory;

/// The reset vector is the address a CPU jumps to when reset.
pub const reset_vector: u32 = 0xbfc00000;

pub const CpuError = error {
    IllegalInstruction,
};

pub const Cpu = struct {
    /// The program counter holds a pointer to the next instruction to be executed by a CPU.
    /// Typically an instruction is read and the counter is then incremented but the pointer may
    /// sometimes be modified directly when the CPU _branches_, enters subroutines, or returns from
    /// them.
    program_counter: u32,
    /// The R3000 has 32 registers. Aside from the first register, $zero, they are all identical;
    /// 32 bits wide. Though there is an extremely common convention defining each of their uses:
    ///
    /// $zero
    /// - Always 0. Loading a value into this register does nothing.
    ///
    /// $at
    /// - "Assembler temporary". Reserved for the assembler, giving it a register to use if
    ///   necessary for certain optimisations or operations.
    ///
    /// $v0, $v1
    /// - Return values of a subroutine.
    ///
    /// $a0 - $a3
    /// - Arguments to a subroutine.
    ///
    /// $t0 - $t7
    /// - Temporary registers used to store intermediary values in operations requiring multiple
    ///   moves. Also may be used by the assembler.
    ///
    /// $s0 - $s7
    /// - Saved registers. Used to store longer lasting values.
    /// TODO: elaborate
    ///
    /// $t8, $t9
    /// - More temporary registers.
    ///
    /// $k0, $k1
    /// - Reserved for use by the kernel, also clobbered by some interrupt request handlers.
    ///
    /// $gp
    /// - Stores a pointer to the global data area.
    /// - Not particularly used by the PlayStation 1.
    ///
    /// $sp
    /// - Stores the stack pointer.
    ///
    /// $fp
    /// - Stores the frame pointer
    ///
    /// $ra
    /// - Stores the return address, i.e. the address of the subroutine that called the current
    ///   subroutine.
    /// - This register is often used as a general purpose register because very few instructions
    ///   use it for its intended purpose.
    registers: [32]u32,
    /// After division operations, hi stores the remainder.
    hi: u32,
    /// After division operations, lo stores the quotient.
    lo: u32,
    memory: Memory,

    pub fn init() Cpu {
        var cpu = Cpu{
            .program_counter = reset_vector,
            .memory = Memory.init(),
            .registers = .{ 0xfacade } ** 32,
            .hi = 0,
            .lo = 0,
        };
        cpu.registers[0] = 0;

        return cpu;
    }

    /// Intended for debugging. Prints what it reasonably can about the CPU's current state.
    pub fn dumpState(self: *Cpu) void {
        log.warn("Something called dumpState.", .{});
        log.info("Registers:\n{x}", .{ self.registers });
        log.info("Hi: {x}", .{ self.hi });
        log.info("Lo: {x}", .{ self.lo });
        log.info("Not dumping memory.", .{});
    }

    inline fn register(self: *Cpu, reg: u32) u32 {
        return self.registers[reg];
    }

    inline fn setRegister(self: *Cpu, reg: u32, value: u32) void {
        self.registers[reg] = value;
        // It's faster to overwrite $zero with 0 than to check if the caller is attempting to
        // overwrite $zero in the first place, so we'll just implement it like this.
        self.registers[0] = 0;
    }

    /// Pull the next instruction, execute it, and advance the program counter.
    pub fn cycle(self: *Cpu) !void {
        const instruction = try self.memory.load32(self.program_counter);
        self.program_counter += 1;
    
        // See below for opcode documentation.
        switch (op.opcodeOf(instruction)) {
            0x0F => self.opLui(instruction),
            0x0D => self.opOri(instruction),
            else => {
                log.err("Illegal instruction encountered! '0x{x}' couldn't be handled.",
                    .{ instruction });
                return CpuError.IllegalInstruction;
            }
        }
    }

    // Instruction implementations

    /// lui: load upper immediate.
    /// Sets the upper 16 bits of a register to a given value.
    /// The lower 16 bits are explicitly set to 0.
    inline fn opLui(self: *Cpu, instruction: u32) void {
        const value = op.iValue(instruction) << 16;
        const destination = op.iDestination(instruction);
        
        self.setRegister(destination, value);
    }

    /// ori: bitwise or immediate.
    /// Performs a bitwise or operation on a register and an immediate value and stores the result
    /// in a second register.
    /// TODO: looks like this is being handled wrong!
    inline fn opOri(self: *Cpu, instruction: u32) void {
        const source = op.source(instruction);
        const destination = op.secondSource(instruction);
        const value = op.iValue(instruction);

        self.setRegister(destination, source | value);
    }
};