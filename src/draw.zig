const std = @import("std");
const Triangle = @import("triangle.zig").Triangle;
const Point = @import("vec.zig").Vec2(f32);

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

    pub inline fn set_point(self: *Buffer, p: Point, color: u32) void {
        self.set(@intFromFloat(@round(p.x)), @intFromFloat(@round(p.y)), color);
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

    pub inline fn fill_rect_point(self: *Buffer, start: Point, width: i64, height: i64, color: u32) void {
        self.fill_rect(@as(i64, @intFromFloat(start.x)), @as(i64, @intFromFloat(start.y)), width, height, color);
    }

    pub fn line(self: *Buffer, p0: Point, p1: Point, color: u32) void {
        const delta = p1.sub(p0);
        const side_length = if (@abs(delta.x) >= @abs(delta.y)) @abs(delta.x) else @abs(delta.y);
        const inc = delta.div(side_length);

        var current = p0;

        for (0..@intFromFloat(side_length)) |_| {
            self.set_point(current, color);
            current = current.add(inc);
        }
    }

    pub fn triangle(self: *Buffer, t: Triangle, color: u32) void {
        const p0 = t.points[0];
        const p1 = t.points[1];
        const p2 = t.points[2];

        self.line(p0, p1, color);
        self.line(p1, p2, color);
        self.line(p2, p0, color);
    }
};

pub fn grid(buf: *Buffer, color: u32) void {
    var y: usize = 0;
    while (y < buf.height) : (y += 10) {
        var x: usize = 0;
        while (x < buf.width) : (x += 10) {
            buf.set(x, y, color);
        }
    }
}

pub fn clear(buf: *Buffer) void {
    buf.fill(0xFF000000);
}
