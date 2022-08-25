//! TODO: General prelude
const testing = @import("testing.zig");

/// The opcode of a MIPS instruction is always the first six bits.
pub inline fn opcodeOf(instruction: u32) u32 {
    return instruction >> 26;
}

/// In R-format and I-format instructions, the first 5 bits after the opcode are called _rs_, for
/// register source - instructions that take a source register to read from take it here.
pub inline fn rs(instruction: u32) u32 {
    return (instruction >> 21) & 0x1f;
}

/// In R-format and I-format instructions, the 5 bits after _rs_ are called _rt_.
/// In R-format instruction this holds the second register source.
/// In I-format instructions it stores the destination register.
pub inline fn rt(instruction: u32) u32 {
    return (instruction >> 16) & 0x1f;
}

/// In R-format instructions, the 5 bits after _rt_ are called _rd_ for register destination,
/// where the instruction will write the result of its operation.
pub inline fn rd(instruction: u32) u32 {
    return (instruction >> 11) & 0x1f;
}

/// In R-format instructions, the 5 bits after _rd_ are called _shamt_, for shift amount.
/// In shift instructions this sets how much to shift by. Otherwise its value doesn't matter,
/// but it's usually zero.
pub inline fn shamt(instruction: u32) u32 {
    return (instruction >> 6) & 0x1f;
}

/// In R-format instructions, the last 6 bits of an instruction are called _funct_, which specifies
/// what variant of the instruction to call (if there's multiple).
pub inline fn funct(instruction: u32) u32 {
    return instruction & 0x3f;
}

/// In I-format instructions, the 16 bits after _rt_ are for the target address or immediate
/// value passed to the instruction.
pub inline fn immediate(instruction: u32) u16 {
    // After the bitmask this value can't be greater than a u16.
    return @truncate(u16, instruction & 0xffff);
}

/// Returns the sign-extended equivalent of immediate.
/// Sign extension refers to the process of increasing the number of bits of an integer while
/// preserving its sign (i.e., extending a negative u16 to a negative u32).
/// Normally converting the number 0b1001 (negative 1) by 4 bits would result in 0b00001001
/// (positive 9). We instead want to convert it to 0b10000001 (also negative 1).
/// To do this, we'll bit cast (re-interpret) the number as a signed 16 bit number, then back to a
/// 32 bit unsigned number.
pub inline fn signedExtendedImmediate(instruction: u32) u32 {
    return @bitCast(u32, @as(i32, immediate(instruction)));
}

/// In J-format instructions, the remaining 26 bits after the opcode are for the target address.
pub inline fn longImmediate(instruction: u32) u32 {
    return instruction & 0x3ffffff;
}

test "Properly decodes R-format instruction" {
    //        opcode   rs    rt    rd    shamt funct
    const x = 0b010011_11111_00000_11011_00100_110011;
    try testing.expectEqual(u32, 0b010011, opcodeOf(x));
    try testing.expectEqual(u32, 0b11111,  rs(x));
    try testing.expectEqual(u32, 0b00000,  rt(x));
    try testing.expectEqual(u32, 0b11011,  rd(x));
    try testing.expectEqual(u32, 0b00100,  shamt(x));
    try testing.expectEqual(u32, 0b110011, funct(x));
}

test "Properly decodes J-format instruction" {
    //        opcode   immediate
    const x = 0b111111_01010101010110011100100101;
    try testing.expectEqual(u32, 0b111111,                     opcodeOf(x));
    try testing.expectEqual(u32, 0b01010101010110011100100101, longImmediate(x));
}

test "Properly decodes I-format instruction" {
    //        opcode  rs    rt    immediate
    const x = 0b00010_10101_00000_1100111010111101;
    try testing.expectEqual(u32, 0b00010,            opcodeOf(x));
    try testing.expectEqual(u32, 0b10101,            rs(x));
    try testing.expectEqual(u32, 0b00000,            rt(x));
    try testing.expectEqual(u32, 0b1100111010111101, immediate(x));
}
test "Properly extends signs" {
    //         opcode  rs    rt    immediate
    const x =  0b00010_10101_00000_1100111010111101;
    try testing.expectEqual(u32, 0b1100111010111101, signedExtendedImmediate(x));
}
