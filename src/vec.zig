pub fn Vec2(comptime T: type) type {
    const SimdVec2 = @Vector(2, T);

    return packed struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn add(self: Self, other: Self) Self {
            const v = self.to_simd() + other.to_simd();
            return from_simd(v);
        }

        pub fn sub(self: Self, other: Self) Self {
            const v = self.to_simd() - other.to_simd();
            return from_simd(v);
        }

        pub fn mul(self: Self, n: T) Self {
            const amount: SimdVec2 = @splat(n);
            return from_simd(self.to_simd() * amount);
        }

        pub fn div(self: Self, n: T) Self {
            const amount: SimdVec2 = @splat(n);
            return from_simd(self.to_simd() / amount);
        }

        pub fn add_s(self: Self, n: T) Self {
            const amount: SimdVec2 = @splat(n);
            return from_simd(self.to_simd() + amount);
        }

        pub fn sub_s(self: Self, n: T) Self {
            const amount: SimdVec2 = @splat(n);
            return from_simd(self.to_simd() - amount);
        }

        pub fn normalize(self: Self) Self {
            const len = self.length();
            return self.div(len);
        }

        pub fn dot(self: Self, other: Self) T {
            const a = self.to_simd();
            const b = other.to_simd();
            return @reduce(.Add, a * b);
        }

        pub fn length(self: Self) T {
            const v = self.to_simd();
            return @sqrt(@reduce(.Add, v * v));
        }

        pub fn trunc(self: Self) Self {
            return from_simd(@trunc(self.to_simd()));
        }

        inline fn from_simd(simd: SimdVec2) Self {
            return @as(Self, @bitCast(simd));
        }

        inline fn to_simd(self: Self) SimdVec2 {
            return @as(SimdVec2, @bitCast(self));
        }
    };
}

pub fn Vec3(comptime T: type) type {
    const SimdVec3 = @Vector(3, T);

    return packed struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,

        pub fn rotate_x(self: Self, angle: T) Self {
            const cos = @cos(angle);
            const sin = @sin(angle);
            return Self{
                .x = self.x,
                .y = self.y * cos - self.z * sin,
                .z = self.y * sin + self.z * cos,
            };
        }

        pub fn rotate_y(self: Self, angle: T) Self {
            const cos = @cos(angle);
            const sin = @sin(angle);
            return Self{
                .x = self.x * cos - self.z * sin,
                .y = self.y,
                .z = self.x * sin + self.z * cos,
            };
        }

        pub fn rotate_z(self: Self, angle: T) Self {
            const cos = @cos(angle);
            const sin = @sin(angle);
            return Self{
                .x = self.x * cos - self.y * sin,
                .y = self.x * sin + self.y * cos,
                .z = self.z,
            };
        }

        pub fn add(self: Self, other: Self) Self {
            const v = self.to_simd() + other.to_simd();
            return from_simd(v);
        }

        pub fn sub(self: Self, other: Self) Self {
            const v = self.to_simd() - other.to_simd();
            return from_simd(v);
        }

        pub fn length(self: Self) T {
            const v = self.to_simd();
            return @sqrt(@reduce(.Add, v * v));
        }

        pub fn add_s(self: Self, n: T) Self {
            const amount: SimdVec3 = @splat(n);
            return from_simd(self.to_simd() + amount);
        }

        pub fn sub_s(self: Self, n: T) Self {
            const amount: SimdVec3 = @splat(n);
            return from_simd(self.to_simd() - amount);
        }

        pub fn mul(self: Self, n: T) Self {
            const amount: SimdVec3 = @splat(n);
            return from_simd(self.to_simd() * amount);
        }

        pub fn div(self: Self, n: T) Self {
            const amount: SimdVec3 = @splat(n);
            return from_simd(self.to_simd() / amount);
        }

        pub fn normalize(self: Self) Self {
            const len = self.length();
            return self.div(len);
        }

        pub fn dot(self: Self, other: Self) T {
            const a = self.to_simd();
            const b = other.to_simd();
            return @reduce(.Add, a * b);
        }

        pub fn cross(self: Self, other: Self) Self {
            const a = self;
            const b = other;

            return .{
                .x = a.y * b.z - a.z * b.y,
                .y = a.z * b.x - a.x * b.z,
                .z = a.x * b.y - a.y * b.x,
            };
        }

        pub fn to_vec4(self: Self, w: T) Vec4(T) {
            return Vec4(T){ .x = self.x, .y = self.y, .z = self.z, .w = w };
        }

        pub inline fn project_perspective(self: Self, comptime fov_factor: f32) Vec2(T) {
            return Vec2(T){ .x = (self.x * fov_factor) / self.z, .y = (self.y * fov_factor) / self.z };
        }

        pub inline fn project_orthographic(self: Self, comptime fov_factor: f32) Vec2(T) {
            return Vec2(T){ .x = (self.x * fov_factor), .y = (self.y * fov_factor) };
        }

        inline fn from_simd(simd: SimdVec3) Self {
            return @as(Self, @bitCast(simd));
        }

        inline fn to_simd(self: Self) SimdVec3 {
            return @as(SimdVec3, @bitCast(self));
        }
    };
}

pub fn Vec4(comptime T: type) type {
    const SimdVec4 = @Vector(4, T);

    return packed struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,
        w: T,

        pub fn add(self: Self, other: Self) Self {
            const v = self.to_simd() + other.to_simd();
            return from_simd(v);
        }

        pub fn sub(self: Self, other: Self) Self {
            const v = self.to_simd() - other.to_simd();
            return from_simd(v);
        }

        pub fn length(self: Self) T {
            const v = self.to_simd();
            return @sqrt(@reduce(.Add, v * v));
        }

        pub fn add_s(self: Self, n: T) Self {
            const amount: SimdVec4 = @splat(n);
            return from_simd(self.to_simd() + amount);
        }

        pub fn sub_s(self: Self, n: T) Self {
            const amount: SimdVec4 = @splat(n);
            return from_simd(self.to_simd() - amount);
        }

        pub fn mul(self: Self, n: T) Self {
            const amount: SimdVec4 = @splat(n);
            return from_simd(self.to_simd() * amount);
        }

        pub fn div(self: Self, n: T) Self {
            const amount: SimdVec4 = @splat(n);
            return from_simd(self.to_simd() / amount);
        }

        pub fn normalize(self: Self) Self {
            const len = self.length();
            return self.div(len);
        }

        pub fn dot(self: Self, other: Self) T {
            const a = self.to_simd();
            const b = other.to_simd();
            return @reduce(.Add, a * b);
        }

        pub fn to_vec3(self: Self) Vec3(T) {
            return Vec3(T){ .x = self.x, .y = self.y, .z = self.z };
        }

        inline fn from_simd(simd: SimdVec4) Self {
            return @as(Self, @bitCast(simd));
        }

        inline fn to_simd(self: Self) SimdVec4 {
            return @as(SimdVec4, @bitCast(self));
        }
    };
}

test "Vec2.add" {
    const std = @import("std");
    const Vec2f32 = Vec2(f32);

    try std.testing.expect(std.meta.eql((Vec2f32{ .x = 1.0, .y = 2.0 }).add(Vec2f32{ .x = 3.0, .y = 4.0 }), Vec2f32{ .x = 4.0, .y = 6.0 }));
}

test "Vec2.length" {
    const testing = @import("std").testing;
    const Vec2f32 = Vec2(f32);

    try testing.expect((Vec2f32{ .x = 3.0, .y = 4.0 }).length() == 5.0);
}

test "Vec3.add" {
    const std = @import("std");
    const Vec3f32 = Vec3(f32);
    try std.testing.expect(std.meta.eql((Vec3f32{ .x = 1.0, .y = 2.0, .z = 3.0 }).add(Vec3f32{ .x = 3.0, .y = 4.0, .z = 5.0 }), Vec3f32{ .x = 4.0, .y = 6.0, .z = 8.0 }));
}

test "Vec3.sub" {
    const std = @import("std");
    const Vec3f32 = Vec3(f32);
    try std.testing.expect(std.meta.eql((Vec3f32{ .x = 1.0, .y = 2.0, .z = 3.0 }).sub(Vec3f32{ .x = 3.0, .y = 4.0, .z = 5.0 }), Vec3f32{ .x = -2.0, .y = -2.0, .z = -2.0 }));
}

test "Vec3.mul" {
    const std = @import("std");
    const Vec3f32 = Vec3(f32);

    try std.testing.expect(std.meta.eql((Vec3f32{ .x = 1.0, .y = 2.0, .z = 3.0 }).mul(2.0), Vec3f32{ .x = 2.0, .y = 4.0, .z = 6.0 }));
}

test "Vec3.div" {
    const std = @import("std");
    const Vec3f32 = Vec3(f32);
    try std.testing.expect(std.meta.eql((Vec3f32{ .x = 1.0, .y = 2.0, .z = 3.0 }).div(2.0), Vec3f32{ .x = 0.5, .y = 1.0, .z = 1.5 }));
}

test "Vec3.dot" {
    const std = @import("std");
    const Vec3f32 = Vec3(f32);
    try std.testing.expect((Vec3f32{ .x = 1.0, .y = 2.0, .z = 3.0 }).dot(Vec3f32{ .x = 3.0, .y = 4.0, .z = 5.0 }) == 26.0);
}

test "Vec3.cross" {
    const std = @import("std");
    const Vec3f32 = Vec3(f32);
    try std.testing.expect(std.meta.eql((Vec3f32{ .x = 1.0, .y = 2.0, .z = 3.0 }).cross(Vec3f32{ .x = 3.0, .y = 4.0, .z = 5.0 }), Vec3f32{ .x = -2.0, .y = 4.0, .z = -2.0 }));
}

test "Vec3.length" {
    const testing = @import("std").testing;
    const Vec3f32 = Vec3(f32);

    try testing.expect((Vec3f32{ .x = 3.0, .y = 4.0, .z = 12.0 }).length() == 13.0);
}
