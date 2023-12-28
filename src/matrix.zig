const Vec3 = @import("vec.zig").Vec3(f32);
const Vec4 = @import("vec.zig").Vec4(f32);

pub const Mat4 = struct {
    m: [4][4]f32,

    pub fn mul_vec4(self: Mat4, vec: Vec4) Vec4 {
        const r0 = self.m[0];
        const r1 = self.m[1];
        const r2 = self.m[2];
        const r3 = self.m[3];

        return Vec4{
            .x = vec.x * r0[0] + vec.y * r1[0] + vec.z * r2[0] + vec.w * r3[0],
            .y = vec.x * r0[1] + vec.y * r1[1] + vec.z * r2[1] + vec.w * r3[1],
            .z = vec.x * r0[2] + vec.y * r1[2] + vec.z * r2[2] + vec.w * r3[2],
            .w = vec.x * r0[3] + vec.y * r1[3] + vec.z * r2[3] + vec.w * r3[3],
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
};
