pub fn Vec2(comptime T: type) type {
    // const Self = @Type();

    return struct {
        x: T,
        y: T,
    };
}

pub fn Vec3(comptime T: type) type {
    // const Self = @Type();

    return struct {
        x: T,
        y: T,
        z: T,
    };
}
