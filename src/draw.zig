const std = @import("std");
const Texture = @import("texture.zig").Texture;
const Tex2 = @import("texture.zig").Tex2;
const Triangle = @import("triangle.zig").Triangle;
const Point = @import("vec.zig").Vec2(f32);
const Vec4 = @import("vec.zig").Vec4(f32);

pub const Buffer = struct {
    allocator: std.mem.Allocator,
    buffer: []u32,
    zbuffer: []f32,
    width: i64,
    height: i64,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Buffer {
        std.debug.assert(width <= std.math.maxInt(i64) and height <= std.math.maxInt(i64));
        const buffer = try allocator.alloc(u32, width * height);
        const zbuffer = try allocator.alloc(f32, width * height);
        return .{
            .allocator = allocator,
            .buffer = buffer,
            .zbuffer = zbuffer,
            .width = @intCast(width),
            .height = @intCast(height),
        };
    }

    pub fn deinit(self: *Buffer) void {
        self.allocator.free(self.buffer);
        self.allocator.free(self.zbuffer);
    }

    pub inline fn set_point(self: *Buffer, p: Point, color: u32, z: f32) void {
        self.set(@intFromFloat(@round(p.x)), @intFromFloat(@round(p.y)), color, z);
    }

    pub inline fn set(self: *Buffer, x: i64, y: i64, color: u32, z: f32) void {
        if (x >= 0 and y >= 0 and x < self.width and y < self.height) {
            const i: usize = @bitCast(y * self.width + x);
            if (z < self.zbuffer[i]) {
                self.buffer[i] = color;
                self.zbuffer[i] = z;
            }
        }
    }

    pub inline fn fill(self: *Buffer, color: u32) void {
        @memset(self.buffer, color);
        @memset(self.zbuffer, 1);
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
                self.set(@bitCast(col), @bitCast(row), color, 0);
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
            self.set_point(current, color, 0);
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

    const TrianglePoint = struct {
        p: Vec4,
        uv: Tex2,
        fn init(p: Vec4, uv: Tex2) TrianglePoint {
            return .{
                .p = .{ .x = @trunc(p.x), .y = @trunc(p.y), .z = p.w, .w = 1 / p.w },
                .uv = uv,
            };
        }
    };
    pub fn fill_triangle_texture(self: *Buffer, t: *const Triangle, texture: *const Texture) void {
        var tp0 = TrianglePoint.init(t.points[0], t.tex_coords[0]);
        var tp1 = TrianglePoint.init(t.points[1], t.tex_coords[1]);
        var tp2 = TrianglePoint.init(t.points[2], t.tex_coords[2]);

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

        const p0 = tp0.p;
        const p1 = tp1.p;
        const p2 = tp2.p;

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
                var x_start = p1.x + (y - p1.y) * inv_slope_1;
                var x_end = p0.x + (y - p0.y) * inv_slope_2;

                if (x_start > x_end) std.mem.swap(f32, &x_start, &x_end);

                var x = x_start;
                while (x <= x_end) : (x += 1) {
                    self.draw_texel(.{ .x = x, .y = y }, tp0, tp1, tp2, texture);
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

                var x_start = p1.x + (y - p1.y) * inv_slope_1;
                var x_end = p0.x + (y - p0.y) * inv_slope_2;
                if (x_start > x_end) std.mem.swap(f32, &x_start, &x_end);

                var x = x_start;
                while (x <= x_end) : (x += 1) {
                    self.draw_texel(.{ .x = x, .y = y }, tp0, tp1, tp2, texture);
                }
            }
        }
    }

    fn draw_texel(self: *Buffer, p: Point, a: TrianglePoint, b: TrianglePoint, c: TrianglePoint, texture: *const Texture) void {
        const weights = Triangle.barycentric_weights(a.p.to_vec2(), b.p.to_vec2(), c.p.to_vec2(), p);

        const alpha = weights.x;
        const beta = weights.y;
        const gamma = weights.z;

        // z contains w and w contains 1/w
        var interpolated_u = (a.uv.u / a.p.z) * alpha + (b.uv.u / b.p.z) * beta + (c.uv.u / c.p.z) * gamma;
        var interpolated_v = (a.uv.v / a.p.z) * alpha + (b.uv.v / b.p.z) * beta + (c.uv.v / c.p.z) * gamma;
        const interpolated_reciprocal_w = a.p.w * alpha + b.p.w * beta + c.p.w * gamma;

        interpolated_u /= interpolated_reciprocal_w;
        interpolated_v /= interpolated_reciprocal_w;

        const color = texture.get_texel(interpolated_u, interpolated_v);
        self.set_point(p, color, 1 - interpolated_reciprocal_w);
    }

    fn draw_pixel(self: *Buffer, p: Point, a: Vec4, b: Vec4, c: Vec4, color: u32) void {
        const weights = Triangle.barycentric_weights(a.to_vec2(), b.to_vec2(), c.to_vec2(), p);

        const alpha = weights.x;
        const beta = weights.y;
        const gamma = weights.z;

        // z contains w and w contains 1/w
        const interpolated_reciprocal_w = a.w * alpha + b.w * beta + c.w * gamma;

        self.set_point(p, color, 1 - interpolated_reciprocal_w);
    }

    pub fn fill_triangle(self: *Buffer, t: Triangle) void {
        var a: Vec4 = .{ .x = @trunc(t.points[0].x), .y = @trunc(t.points[0].y), .z = t.points[0].w, .w = 1 / t.points[0].w };
        var b: Vec4 = .{ .x = @trunc(t.points[1].x), .y = @trunc(t.points[1].y), .z = t.points[1].w, .w = 1 / t.points[1].w };
        var c: Vec4 = .{ .x = @trunc(t.points[2].x), .y = @trunc(t.points[2].y), .z = t.points[2].w, .w = 1 / t.points[2].w };

        const T = @TypeOf(a);

        if (a.y > b.y) {
            std.mem.swap(T, &a, &b);
        }
        if (b.y > c.y) {
            std.mem.swap(T, &b, &c);

            if (a.y > b.y) {
                std.mem.swap(T, &a, &b);
            }
        }

        const p0 = a.to_vec2().trunc();
        const p1 = b.to_vec2().trunc();
        const p2 = c.to_vec2().trunc();

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
                var x_start = p1.x + (y - p1.y) * inv_slope_1;
                var x_end = p0.x + (y - p0.y) * inv_slope_2;

                if (x_start > x_end) std.mem.swap(f32, &x_start, &x_end);

                var x = x_start;
                while (x <= x_end) : (x += 1) {
                    self.draw_pixel(.{ .x = x, .y = y }, a, b, c, t.color);
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

                var x_start = p1.x + (y - p1.y) * inv_slope_1;
                var x_end = p0.x + (y - p0.y) * inv_slope_2;
                if (x_start > x_end) std.mem.swap(f32, &x_start, &x_end);

                var x = x_start;
                while (x <= x_end) : (x += 1) {
                    self.draw_pixel(.{ .x = x, .y = y }, a, b, c, t.color);
                }
            }
        }
    }
};

pub fn grid(buf: *Buffer, color: u32) void {
    var y: i64 = 0;
    while (y < buf.height) : (y += 10) {
        var x: i64 = 0;
        while (x < buf.width) : (x += 10) {
            buf.set(x, y, color, 0);
        }
    }
}

pub fn clear(buf: *Buffer) void {
    buf.fill(0xFF000000);
}
