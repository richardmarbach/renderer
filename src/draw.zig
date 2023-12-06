const std = @import("std");

pub const Buffer = struct {
    allocator: std.mem.Allocator,
    buffer: []u32,
    width: i64,
    height: i64,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Buffer {
        std.debug.assert(width <= std.math.maxInt(i64) and height <= std.math.maxInt(i64));
        const buffer = try allocator.alloc(u32, width * height);
        return .{ .allocator = allocator, .buffer = buffer, .width = @intCast(width), .height = @intCast(height) };
    }

    pub fn deinit(self: *Buffer) void {
        self.allocator.free(self.buffer);
    }

    pub inline fn set(self: *Buffer, x: usize, y: usize, color: u32) void {
        std.debug.assert(x < self.width and y < self.height);
        self.buffer[y * @as(usize, @bitCast(self.width)) + x] = color;
    }

    pub inline fn fill(self: *Buffer, color: u32) void {
        @memset(self.buffer, color);
    }

    pub inline fn width_f32(self: *Buffer) f32 {
        return @floatFromInt(self.width);
    }

    pub inline fn height_f32(self: *Buffer) f32 {
        return @floatFromInt(self.height);
    }

    pub fn fill_rect(self: *Buffer, x: i64, y: i64, width: i64, height: i64, color: u32) void {
        const x_s = @max(x, 0);
        const y_s = @max(y, 0);
        const h = @min(y + height, self.height);
        const w = @min(x + width, self.width);
        for (@max(y_s, 0)..@max(h, 0)) |row| {
            for (@max(x_s, 0)..@max(w, 0)) |col| {
                self.set(col, row, color);
            }
        }
    }

    pub fn line(self: *Buffer, x0: i64, y0: i64, x1: i64, y1: i64, color: u32) void {
        const delta_x = x1 - x0;
        const delta_y = y1 - y0;
        const side_length = if (@abs(delta_x) >= @abs(delta_y)) @abs(delta_x) else @abs(delta_y);

        const x_inc: f32 = @as(f32, @floatFromInt(delta_x)) / @as(f32, @floatFromInt(side_length));
        const y_inc: f32 = @as(f32, @floatFromInt(delta_y)) / @as(f32, @floatFromInt(side_length));

        var current_x: f32 = @floatFromInt(x0);
        var current_y: f32 = @floatFromInt(y0);

        for (0..side_length) |_| {
            self.set(@intFromFloat(@round(current_x)), @intFromFloat(@round(current_y)), color);
            current_x += x_inc;
            current_y += y_inc;
        }
    }

    pub fn triangle(self: *Buffer, x0: i64, y0: i64, x1: i64, y1: i64, x2: i64, y2: i64, color: u32) void {
        self.line(x0, y0, x1, y1, color);
        self.line(x1, y1, x2, y2, color);
        self.line(x2, y2, x0, y0, color);
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
