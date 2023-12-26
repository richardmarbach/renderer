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

    pub fn line(self: *Buffer, p0a: Point, p1a: Point, color: u32) void {
        const p0 = p0a.trunc();
        const p1 = p1a.trunc();

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
        const p0 = t.points[0].trunc();
        const p1 = t.points[1].trunc();
        const p2 = t.points[2].trunc();

        self.line(p0, p1, color);
        self.line(p1, p2, color);
        self.line(p2, p0, color);
    }

    pub fn fill_triangle(self: *Buffer, t: Triangle, color: u32) void {
        var p0 = t.points[0].trunc();
        var p1 = t.points[1].trunc();
        var p2 = t.points[2].trunc();

        const T = @TypeOf(p0);

        if (p0.y > p1.y) {
            std.mem.swap(T, &p0, &p1);
        }
        if (p1.y > p2.y) {
            std.mem.swap(T, &p1, &p2);

            if (p0.y > p1.y) {
                std.mem.swap(T, &p0, &p1);
            }
        }

        if (p1.y == p2.y) {
            self.fill_flat_bottom_triangle(p0, p1, p2, color);
            return;
        }

        if (p0.y == p1.y) {
            self.fill_flat_top_triangle(p0, p1, p2, color);
            return;
        }

        const m: Point = Point{
            .x = @trunc(((p2.x - p0.x) * (p1.y - p0.y)) / (p2.y - p0.y) + p0.x),
            .y = @trunc(p1.y),
        };

        self.fill_flat_bottom_triangle(p0, p1, m, color);
        self.fill_flat_top_triangle(p1, m, p2, color);
    }

    fn fill_flat_bottom_triangle(self: *Buffer, p0: Point, p1: Point, p2: Point, color: u32) void {
        const side1 = p1.sub(p0);
        const side2 = p2.sub(p0);

        const inv_s1 = .{ .x = side1.x / side1.y, .y = 1.0 };
        const inv_s2 = .{ .x = side2.x / side2.y, .y = 1.0 };

        const height: usize = @intFromFloat(side2.y);

        var start = p0;
        var end = p0;

        for (0..height + 1) |_| {
            self.line(start, end, color);

            start = start.add(inv_s1);
            end = end.add(inv_s2);
        }
    }

    fn fill_flat_top_triangle(self: *Buffer, p0: Point, p1: Point, p2: Point, color: u32) void {
        const side1 = p2.sub(p0);
        const side2 = p2.sub(p1);

        const inv_s1 = .{ .x = side1.x / side1.y, .y = 1.0 };
        const inv_s2 = .{ .x = side2.x / side2.y, .y = 1.0 };

        const height: usize = @intFromFloat(side2.y);

        var start = p2;
        var end = p2;

        for (0..height + 1) |_| {
            self.line(start, end, color);

            start = start.sub(inv_s1);
            end = end.sub(inv_s2);
        }
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
