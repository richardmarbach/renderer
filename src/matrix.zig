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

    pub fn project_vec4(self: Mat4, vec: Vec4) Vec4 {
        var result = self.mul_vec4(vec);

        if (result.w != 0.0) {
            result.x /= result.w;
            result.y /= result.w;
            result.z /= result.w;
        }
        return result;
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

    pub fn init_perspective(fov: f32, aspect: f32, znear: f32, zfar: f32) Mat4 {
        const f = 1.0 / @tan(fov / 2.0);

        return Mat4{
            .m = [_][4]f32{
                [_]f32{ aspect * f, 0.0, 0.0, 0.0 },
                [_]f32{ 0.0, f, 0.0, 0.0 },
                [_]f32{ 0.0, 0.0, zfar / (zfar - znear), (-zfar * znear) / (zfar - znear) },
                [_]f32{ 0.0, 0.0, 1.0, 0.0 },
            },
        };
    }
};

test "matrix multiplication" {
    const std = @import("std");
    const mat = Mat4{
        .m = [_][4]f32{
            [_]f32{ 1.0, 2.0, 3.0, 4.0 },
            [_]f32{ 5.0, 6.0, 7.0, 8.0 },
            [_]f32{ 9.0, 10.0, 11.0, 12.0 },
            [_]f32{ 13.0, 14.0, 15.0, 16.0 },
        },
    };

    const identity = Mat4.init_identity();

    try std.testing.expect(std.meta.eql(identity.mul(mat), mat));
    try std.testing.expect(std.meta.eql(mat.mul(identity), mat));

    const scale = Mat4{
        .m = [_][4]f32{
            [_]f32{ 0.0, 1.0, 2.0, 3.0 },
            [_]f32{ 0.0, 1.0, 2.0, 3.0 },
            [_]f32{ 0.0, 1.0, 2.0, 3.0 },
            [_]f32{ 0.0, 1.0, 2.0, 3.0 },
        },
    };

    const result = Mat4{
        .m = [_][4]f32{
            [_]f32{ 0.0, 10.0, 20.0, 30.0 },
            [_]f32{ 0.0, 26.0, 52.0, 78.0 },
            [_]f32{ 0.0, 42.0, 84.0, 126.0 },
            [_]f32{ 0.0, 58.0, 116.0, 174.0 },
        },
    };

    try std.testing.expect(std.meta.eql(mat.mul(scale), result));
}

test "transpose" {
    const std = @import("std");
    const mat = Mat4{
        .m = [_][4]f32{
            [_]f32{ 1.0, 2.0, 3.0, 4.0 },
            [_]f32{ 5.0, 6.0, 7.0, 8.0 },
            [_]f32{ 9.0, 10.0, 11.0, 12.0 },
            [_]f32{ 13.0, 14.0, 15.0, 16.0 },
        },
    };

    const transposed = Mat4{
        .m = [_][4]f32{
            [_]f32{ 1.0, 5.0, 9.0, 13.0 },
            [_]f32{ 2.0, 6.0, 10.0, 14.0 },
            [_]f32{ 3.0, 7.0, 11.0, 15.0 },
            [_]f32{ 4.0, 8.0, 12.0, 16.0 },
        },
    };

    try std.testing.expect(std.meta.eql(mat.transpose(), transposed));
}
