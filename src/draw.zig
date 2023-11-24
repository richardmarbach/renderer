const std = @import("std");

pub const Buffer = struct {
    allocator: std.mem.Allocator,
    buffer: []u32,
    width: usize,
    height: usize,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Buffer {
        const buffer = try allocator.alloc(u32, width * height);
        return .{ .allocator = allocator, .buffer = buffer, .width = width, .height = height };
    }

    pub fn deinit(self: *Buffer) void {
        self.allocator.free(self.buffer);
    }

    pub inline fn set(self: *Buffer, x: usize, y: usize, color: u32) void {
        std.debug.assert(x < self.width and y < self.height);
        self.buffer[y * self.width + x] = color;
    }

    pub inline fn fill(self: *Buffer, color: u32) void {
        @memset(self.buffer, color);
    }

    pub fn fill_rect(self: *Buffer, x: usize, y: usize, width: usize, height: usize, color: u32) void {
        const h = @min(y + height, self.height);
        const w = @min(x + width, self.width);
        for (y..h) |row| {
            for (x..w) |col| {
                self.set(col, row, color);
            }
        }
    }
};

pub fn grid(buf: *Buffer) void {
    var y: usize = 0;
    while (y < buf.height) : (y += 10) {
        var x: usize = 0;
        while (x < buf.width) : (x += 10) {
            buf.set(x, y, 0xFF333333);
        }
    }
}

pub fn clear(buf: *Buffer) void {
    buf.fill(0xFF000000);
}
