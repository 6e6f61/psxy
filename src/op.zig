//! TODO: General prelude

/// The opcode of a MIPS instruction is always the first six bits.
pub inline fn opcodeOf(instruction: u32) u32 {
    return instruction >> 26;
}

/// In R-format and I-format instructions, the first 5 bits after the opcode are called _rs_, for
/// register source - instructions that take a source register to read from take it here.
pub inline fn source(instruction: u32) u32 {
    // rs
    return (instruction >> 21) & 0x1f;
}

/// In R-format and I-format instructions, the 5 bits after _rs_ are called _rt_.
/// In R-format instruction this holdings the second register source.
/// In I-format instructions it stores the destination register.
pub inline fn secondSource(instruction: u32) u32 {
    // rt
    return (instruction >> 16) & 0x1f;
}

/// A wrapper around secondSource for use with I-format instructions for a cleaner API.
pub inline fn iDestination(instruction: u32) u32 {
    return secondSource(instruction);
}

/// In R-format instructions, the 5 bits after _rt_ are called _rd_ for register destination,
/// where the instruction will write the result of its operation.
pub inline fn rDestination(instruction: u32) u32 {
    // d
    return (instruction >> 11) & 0x1f;
}

/// In R-format instructions, the 5 bits after _rd_ are called _shamt_, for shift amount.
/// In shift instructions this sets how much to shift by. Otherwise its value doesn't matter,
/// but it's usually zero.
pub inline fn shiftAmount(instruction: u32) u32 {
    return (instruction >> 6) & 0x1f;
}

/// In R-format instructions, the last 6 bits of an instruction are called _funct_, which specifies
/// what variant of the instruction to call (if there's multiple).
pub inline fn funct(instruction: u32) u32 {
    return instruction & 0x3f;
}

/// In I-format instructions, the 16 bits after _rt_ are for the target address or immediate
/// value passed to the instruction.
pub inline fn iValue(instruction: u32) u32 {
    return instruction & 0xfffff;
}

/// In J-format instructions, the remaining 26 bits after the opcode are for the target address.
pub inline fn jValue(instruction: u32) u32 {
    return instruction & 0x3ffffff;
}