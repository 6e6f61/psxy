const testing = @import("std").testing;

/// Small shim around testing.expectEqual that swaps the typing to take the type of
/// actual rather than expected, because the way std does it is dumb.
pub inline fn expectEqual(comptime T: type, expected: T, actual: T) !void {
    try testing.expectEqual(expected, actual);
}