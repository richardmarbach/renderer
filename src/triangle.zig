const Vec2 = @import("vec.zig").Vec2;

pub const Face = struct {
    a: usize,
    b: usize,
    c: usize,
    color: u32,
};

pub const Triangle = struct {
    points: [3]Vec2(f32),
    color: u32,
    z: f32,

    pub fn cmp(_: void, a: Triangle, b: Triangle) bool {
        return a.z < b.z;
    }
};
