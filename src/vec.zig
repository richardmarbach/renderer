pub fn Vec2(comptime T: type) type {
    const SimdVec2 = @Vector(2, T);

    return packed struct {
        const Self = @This();

        x: T,
        y: T,

        inline fn fromSimd(simd: SimdVec2) Self {
            return @as(Self, @bitCast(simd));
        }

        inline fn toSimd(self: Self) SimdVec2 {
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

        pub fn sub(self: Self, other: Self) Self {
            return Self{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }

        pub fn magnitude(self: Self) T {
            const v = self.toSimd();
            return @sqrt(@reduce(.Add, v * v));
        }

        pub fn add_s(self: Self, n: T) Self {
            const amount: SimdVec3 = @splat(n);
            return fromSimd(self.toSimd() + amount);
        }

        inline fn fromSimd(simd: SimdVec3) Self {
            return @as(Self, @bitCast(simd));
        }

        inline fn toSimd(self: Self) SimdVec3 {
            return @as(SimdVec3, @bitCast(self));
        }
    };
}
