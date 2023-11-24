const std = @import("std");

pub const DrawBuffer = struct {
    allocator: std.mem.Allocator,
    buffer: []u32,
    width: usize,
    height: usize,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !DrawBuffer {
        const buffer = try allocator.alloc(u32, width * height);
        @memset(buffer, 0xFF000000);
        return .{ .allocator = allocator, .buffer = buffer, .width = width, .height = height };
    }

    pub fn deinit(self: *DrawBuffer) void {
        self.allocator.free(self.buffer);
    }

    pub fn draw_grid(self: *DrawBuffer) void {
        var y: usize = 0;
        while (y < self.height) : (y += 10) {
            var x: usize = 0;
            while (x < self.width) : (x += 10) {
                self.buffer[y * self.width + x] = 0xFF333333;
            }
        }
    }

    pub fn draw_rect(self: *DrawBuffer, x: usize, y: usize, width: usize, height: usize, color: u32) void {
        const h = @min(y + height, self.height);
        const w = @min(x + width, self.width);
        for (y..h) |row| {
            for (x..w) |col| {
                self.buffer[row * self.width + col] = color;
            }
        }
    }

    pub fn clear(self: *DrawBuffer) void {
        @memset(self.buffer, 0xFF000000);
    }
};
