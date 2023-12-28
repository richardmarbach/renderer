const Vec3 = @import("vec.zig").Vec3(f32);
const Vec4 = @import("vec.zig").Vec4(f32);

pub const Mat4 = struct {
    m: [4][4]f32,

    const SimdRow = @Vector(4, f32);

    pub fn mul(self: Mat4, other: Mat4) Mat4 {
        const r0: SimdRow = self.m[0];
        const r1: SimdRow = self.m[1];
        const r2: SimdRow = self.m[2];
        const r3: SimdRow = self.m[3];

        const t = other.transpose();
        const c0: SimdRow = t.m[0];
        const c1: SimdRow = t.m[1];
        const c2: SimdRow = t.m[2];
        const c3: SimdRow = t.m[3];

        return Mat4{
            .m = [_][4]f32{
                [_]f32{ @reduce(.Add, r0 * c0), @reduce(.Add, r0 * c1), @reduce(.Add, r0 * c2), @reduce(.Add, r0 * c3) },
                [_]f32{ @reduce(.Add, r1 * c0), @reduce(.Add, r1 * c1), @reduce(.Add, r1 * c2), @reduce(.Add, r1 * c3) },
                [_]f32{ @reduce(.Add, r2 * c0), @reduce(.Add, r2 * c1), @reduce(.Add, r2 * c2), @reduce(.Add, r2 * c3) },
                [_]f32{ @reduce(.Add, r3 * c0), @reduce(.Add, r3 * c1), @reduce(.Add, r3 * c2), @reduce(.Add, r3 * c3) },
            },
        };
    }

    pub fn mul_vec4(self: Mat4, vec: Vec4) Vec4 {
        const r0: SimdRow = self.m[0];
        const r1: SimdRow = self.m[1];
        const r2: SimdRow = self.m[2];
        const r3: SimdRow = self.m[3];

        const v = vec.to_simd();

        return Vec4{
            .x = @reduce(.Add, r0 * v),
            .y = @reduce(.Add, r1 * v),
            .z = @reduce(.Add, r2 * v),
            .w = @reduce(.Add, r3 * v),
        };
    }

    pub fn transpose(self: Mat4) Mat4 {
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ self.m[0][0], self.m[1][0], self.m[2][0], self.m[3][0] },
                [_]f32{ self.m[0][1], self.m[1][1], self.m[2][1], self.m[3][1] },
                [_]f32{ self.m[0][2], self.m[1][2], self.m[2][2], self.m[3][2] },
                [_]f32{ self.m[0][3], self.m[1][3], self.m[2][3], self.m[3][3] },
            },
        };
    }

    pub fn init_rotation_x(angle: f32) Mat4 {
        const cos = @cos(angle);
        const sin = @sin(angle);
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ 1.0, 0.0, 0.0, 0.0 },
                [_]f32{ 0.0, cos, -sin, 0.0 },
                [_]f32{ 0.0, sin, cos, 0.0 },
                [_]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }

    pub fn init_rotation_y(angle: f32) Mat4 {
        const cos = @cos(angle);
        const sin = @sin(angle);
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ cos, 0.0, sin, 0.0 },
                [_]f32{ 0.0, 1.0, 0.0, 0.0 },
                [_]f32{ -sin, 0.0, cos, 0.0 },
                [_]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }

    pub fn init_rotation_z(angle: f32) Mat4 {
        const cos = @cos(angle);
        const sin = @sin(angle);
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ cos, -sin, 0.0, 0.0 },
                [_]f32{ sin, cos, 0.0, 0.0 },
                [_]f32{ 0.0, 0.0, 1.0, 0.0 },
                [_]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }

    pub fn init_identity() Mat4 {
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ 1.0, 0.0, 0.0, 0.0 },
                [_]f32{ 0.0, 1.0, 0.0, 0.0 },
                [_]f32{ 0.0, 0.0, 1.0, 0.0 },
                [_]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }

    pub fn init_scale(s: Vec3) Mat4 {
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ s.x, 0.0, 0.0, 0.0 },
                [_]f32{ 0.0, s.y, 0.0, 0.0 },
                [_]f32{ 0.0, 0.0, s.z, 0.0 },
                [_]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }

    pub fn init_translation(t: Vec3) Mat4 {
        return Mat4{
            .m = [_][4]f32{
                [_]f32{ 1.0, 0.0, 0.0, t.x },
                [_]f32{ 0.0, 1.0, 0.0, t.y },
                [_]f32{ 0.0, 0.0, 1.0, t.z },
                [_]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }
};
