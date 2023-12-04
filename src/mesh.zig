const vec = @import("vec.zig");
const Face = @import("triangle.zig").Face;
const Vec3 = vec.Vec3(f32);

pub const vertices = [_]Vec3{
    .{ .x = -1.0, .y = -1.0, .z = -1.0 }, // 1
    .{ .x = -1.0, .y = 1.0, .z = -1.0 }, // 2
    .{ .x = 1.0, .y = 1.0, .z = -1.0 }, // 3
    .{ .x = 1.0, .y = -1.0, .z = -1.0 }, // 4
    .{ .x = 1.0, .y = 1.0, .z = 1.0 }, // 5
    .{ .x = 1.0, .y = -1.0, .z = 1.0 }, // 6
    .{ .x = -1.0, .y = 1.0, .z = 1.0 }, // 7
    .{ .x = -1.0, .y = -1.0, .z = 1.0 }, // 8
};

pub const faces = [_]Face{
    // Front
    .{ .a = 1, .b = 2, .c = 3 },
    .{ .a = 1, .b = 3, .c = 4 },

    // right
    .{ .a = 4, .b = 3, .c = 5 },
    .{ .a = 4, .b = 5, .c = 6 },

    // back
    .{ .a = 6, .b = 5, .c = 7 },
    .{ .a = 6, .b = 7, .c = 8 },

    // left
    .{ .a = 8, .b = 7, .c = 2 },
    .{ .a = 8, .b = 2, .c = 1 },

    // top
    .{ .a = 2, .b = 7, .c = 5 },
    .{ .a = 2, .b = 5, .c = 3 },

    // bottom
    .{ .a = 6, .b = 8, .c = 1 },
    .{ .a = 6, .b = 1, .c = 4 },
};
