pub fn Vec2(comptime T: type) type {
    const SimdVec2 = @Vector(2, T);

    const Self = @This();

    return extern struct {
        x: T align(@alignOf(SimdVec2)),
        y: T,

        fn fromSimd(simd: SimdVec2) Self {
            return @as(Self, @bitCast(simd));
        }

        fn toSimd(self: Self) SimdVec2 {
            return @as(SimdVec2, @bitCast(self));
        }
    };
}

pub fn Vec3(comptime T: type) type {
    const SimdVec3 = @Vector(3, T);

    const Self = @This();

    return extern struct {
        x: T align(@alignOf(SimdVec3)),
        y: T,
        z: T,

        fn fromSimd(simd: SimdVec3) Self {
            return @as(Self, @bitCast(simd));
        }

        fn toSimd(self: Self) SimdVec3 {
            return @as(SimdVec3, @bitCast(self));
        }
    };
}
