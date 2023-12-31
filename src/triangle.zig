const Vec2 = @import("vec.zig").Vec2(f32);
const Vec3 = @import("vec.zig").Vec3(f32);
const Vec4 = @import("vec.zig").Vec4(f32);
const Tex2 = @import("texture.zig").Tex2;

pub const Face = struct {
    a: usize,
    b: usize,
    c: usize,
    a_uv: Tex2,
    b_uv: Tex2,
    c_uv: Tex2,
    color: u32,
};

pub const Triangle = struct {
    points: [3]Vec4,
    tex_coords: [3]Tex2,
    color: u32,
    z: f32,

    pub fn cmp(_: void, a: Triangle, b: Triangle) bool {
        return a.z > b.z;
    }

    pub fn barycentric_weights(a: Vec2, b: Vec2, c: Vec2, p: Vec2) Vec3 {
        const ac = c.sub(a);
        const ab = b.sub(a);
        const ap = p.sub(a);
        const pc = c.sub(p);
        const pb = b.sub(p);

        const area_parallelogram_abc = ac.cross(ab);
        const alpha = pc.cross(pb) / area_parallelogram_abc;
        const beta = ac.cross(ap) / area_parallelogram_abc;
        const gamma = 1.0 - alpha - beta;
        return .{ .x = alpha, .y = beta, .z = gamma };
    }
};
