const std = @import("std");
const Texture = @import("texture.zig").Texture;
const Tex2 = @import("texture.zig").Tex2;
const Triangle = @import("triangle.zig").Triangle;
const Point = @import("vec.zig").Vec2(f32);
const Vec4 = @import("vec.zig").Vec4(f32);

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

    pub inline fn set(self: *Buffer, x: i64, y: i64, color: u32) void {
        if (x >= 0 and y >= 0 and x < self.width and y < self.height) {
            self.buffer[@bitCast(y * self.width + x)] = color;
        }
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
                self.set(@bitCast(col), @bitCast(row), color);
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

        for (0..@intFromFloat(side_length + 1)) |_| {
            self.set_point(current, color);
            current = current.add(inc);
        }
    }

    pub fn triangle(self: *Buffer, t: Triangle, color: u32) void {
        const p0 = t.points[0].to_vec2().trunc();
        const p1 = t.points[1].to_vec2().trunc();
        const p2 = t.points[2].to_vec2().trunc();

        self.line(p0, p1, color);
        self.line(p1, p2, color);
        self.line(p2, p0, color);
    }

    const TrianglePoint = struct { p: Vec4, uv: Tex2 };
    pub fn fill_triangle_texture(self: *Buffer, t: *const Triangle, texture: *const Texture) void {
        var tp0: TrianglePoint = .{ .p = t.points[0], .uv = t.tex_coords[0] };
        var tp1: TrianglePoint = .{ .p = t.points[1], .uv = t.tex_coords[1] };
        var tp2: TrianglePoint = .{ .p = t.points[2], .uv = t.tex_coords[2] };

        const T = @TypeOf(tp0);

        if (tp0.p.y > tp1.p.y) {
            std.mem.swap(T, &tp0, &tp1);
        }
        if (tp1.p.y > tp2.p.y) {
            std.mem.swap(T, &tp1, &tp2);

            if (tp0.p.y > tp1.p.y) {
                std.mem.swap(T, &tp0, &tp1);
            }
        }

        const p0 = tp0.p.trunc();
        const p1 = tp1.p.trunc();
        const p2 = tp2.p.trunc();

        const y0: usize = @intFromFloat(p0.y);
        const y1: usize = @intFromFloat(p1.y);
        const y2: usize = @intFromFloat(p2.y);

        // Draw flat-bottom triangle
        var inv_slope_1: f32 = 0;
        var inv_slope_2: f32 = 0;

        if (p1.y - p0.y != 0) {
            inv_slope_1 = (p1.x - p0.x) / (p1.y - p0.y);
        }

        if (p2.y - p0.y != 0) {
            inv_slope_2 = (p2.x - p0.x) / (p2.y - p0.y);
        }

        if (y1 - y0 != 0) {
            for (y0..y1 + 1) |y_u| {
                const y: f32 = @floatFromInt(y_u);
                const x_start = p1.x + (y - p1.y) * inv_slope_1;
                const x_end = p0.x + (y - p0.y) * inv_slope_2;

                var x0: usize = @intFromFloat(x_start);
                var x1: usize = @intFromFloat(x_end);

                if (x0 > x1) {
                    std.mem.swap(usize, &x0, &x1);
                }
                for (x0..x1) |x| {
                    const x_i: i64 = @bitCast(x);
                    const y_i: i64 = @bitCast(y_u);
                    self.draw_texel(x_i, y_i, tp0, tp1, tp2, texture);
                }
            }
        }

        // Draw flat-top triangle

        inv_slope_1 = 0;
        inv_slope_2 = 0;

        if (p2.y - p1.y != 0) {
            inv_slope_1 = (p2.x - p1.x) / (p2.y - p1.y);
        }
        if (p2.y - p0.y != 0) {
            inv_slope_2 = (p2.x - p0.x) / (p2.y - p0.y);
        }

        if (y2 - y1 != 0) {
            for (y1..y2 + 1) |y_u| {
                const y: f32 = @floatFromInt(y_u);

                const x_start = p1.x + (y - p1.y) * inv_slope_1;
                const x_end = p0.x + (y - p0.y) * inv_slope_2;

                var x0: usize = @intFromFloat(@trunc(x_start));
                var x1: usize = @intFromFloat(@trunc(x_end));

                if (x0 > x1) {
                    std.mem.swap(usize, &x0, &x1);
                }
                for (x0..x1 + 1) |x| {
                    const x_i: i64 = @bitCast(x);
                    const y_i: i64 = @bitCast(y_u);
                    self.draw_texel(x_i, y_i, tp0, tp1, tp2, texture);
                }
            }
        }
    }

    fn draw_texel(self: *Buffer, x: i64, y: i64, a: TrianglePoint, b: TrianglePoint, c: TrianglePoint, texture: *const Texture) void {
        const p: Point = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
        const weights = Triangle.barycentric_weights(a.p.to_vec2(), b.p.to_vec2(), c.p.to_vec2(), p);

        const alpha = weights.x;
        const beta = weights.y;
        const gamma = weights.z;

        var interpolated_u = (a.uv.u / a.p.w) * alpha + (b.uv.u / b.p.w) * beta + (c.uv.u / c.p.w) * gamma;
        var interpolated_v = (a.uv.v / a.p.w) * alpha + (b.uv.v / b.p.w) * beta + (c.uv.v / c.p.w) * gamma;
        const interpolated_reciprocal_w = (1 / a.p.w) * alpha + (1 / b.p.w) * beta + (1 / c.p.w) * gamma;

        interpolated_u /= interpolated_reciprocal_w;
        interpolated_v /= interpolated_reciprocal_w;

        const color = texture.get_texel(interpolated_u, interpolated_v);
        self.set(x, y, color);
    }

    pub fn fill_triangle(self: *Buffer, t: Triangle) void {
        var p0 = t.points[0].to_vec2().trunc();
        var p1 = t.points[1].to_vec2().trunc();
        var p2 = t.points[2].to_vec2().trunc();

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
            self.fill_flat_bottom_triangle(p0, p1, p2, t.color);
            return;
        }

        if (p0.y == p1.y) {
            self.fill_flat_top_triangle(p0, p1, p2, t.color);
            return;
        }

        const m: Point = Point{
            .x = @trunc(((p2.x - p0.x) * (p1.y - p0.y)) / (p2.y - p0.y) + p0.x),
            .y = @trunc(p1.y),
        };

        self.fill_flat_bottom_triangle(p0, p1, m, t.color);
        self.fill_flat_top_triangle(p1, m, p2, t.color);
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
    var y: i64 = 0;
    while (y < buf.height) : (y += 10) {
        var x: i64 = 0;
        while (x < buf.width) : (x += 10) {
            buf.set(x, y, color);
        }
    }
}

pub fn clear(buf: *Buffer) void {
    buf.fill(0xFF000000);
}
