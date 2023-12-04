const Vec2 = @import("vec.zig").Vec2;

pub const Face = struct { a: usize, b: usize, c: usize };

pub const Triangle = struct { points: [3]Vec2(f32) };
