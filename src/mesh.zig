const std = @import("std");
const vec = @import("vec.zig");
const Texture = @import("texture.zig").Texture;
const Face = @import("triangle.zig").Face;
const Vec3 = vec.Vec3(f32);
const obj = @import("obj.zig");

pub const Mesh = struct {
    vertices: []const Vec3,
    faces: []const Face,
    rotation: Vec3,
    scale: Vec3,
    translation: Vec3,
    texture: *const Texture,

    obj_file: ?obj.File,

    pub fn deinit(self: *Mesh) void {
        if (self.obj_file) |*f| {
            f.deinit();
        } else {
            std.heap.page_allocator.free(self.vertices);
            std.heap.page_allocator.free(self.faces);
        }
    }

    pub inline fn face_vertices(self: *const Mesh, face: *const Face) [3]Vec3 {
        return [3]Vec3{ self.vertices[face.a - 1], self.vertices[face.b - 1], self.vertices[face.c - 1] };
    }

    pub fn load_obj(allocator: std.mem.Allocator, file_path: []const u8, texture: *const Texture) !Mesh {
        const obj_file = try obj.load(allocator, file_path);
        return Mesh{
            .vertices = obj_file.vertices.items,
            .faces = obj_file.faces.items,
            .texture = texture,
            .rotation = .{ .x = 0, .y = 0, .z = 0 },
            .scale = .{ .x = 1, .y = 1, .z = 1 },
            .translation = .{ .x = 0, .y = 0, .z = 0 },

            .obj_file = obj_file,
        };
    }

    pub fn init_cube(texture: *const Texture) !Mesh {
        const vertices = [_]Vec3{
            .{ .x = -1, .y = -1, .z = -1 }, // 1
            .{ .x = -1, .y = 1, .z = -1 }, // 2
            .{ .x = 1, .y = 1, .z = -1 }, // 3
            .{ .x = 1, .y = -1, .z = -1 }, // 4
            .{ .x = 1, .y = 1, .z = 1 }, // 5
            .{ .x = 1, .y = -1, .z = 1 }, // 6
            .{ .x = -1, .y = 1, .z = 1 }, // 7
            .{ .x = -1, .y = -1, .z = 1 }, // 8
        };
        const faces = [_]Face{
            // Front
            .{ .a = 1, .b = 2, .c = 3, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 0, .v = 0 }, .c_uv = .{ .u = 1, .v = 0 }, .color = 0xFFFFFFFF },
            .{ .a = 1, .b = 3, .c = 4, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 1, .v = 0 }, .c_uv = .{ .u = 1, .v = 1 }, .color = 0xFFFFFFFF },
            // right
            .{ .a = 4, .b = 3, .c = 5, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 0, .v = 0 }, .c_uv = .{ .u = 1, .v = 0 }, .color = 0xFFFFFFFF },
            .{ .a = 4, .b = 5, .c = 6, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 1, .v = 0 }, .c_uv = .{ .u = 1, .v = 1 }, .color = 0xFFFFFFFF },
            // back
            .{ .a = 6, .b = 5, .c = 7, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 0, .v = 0 }, .c_uv = .{ .u = 1, .v = 0 }, .color = 0xFFFFFFFF },
            .{ .a = 6, .b = 7, .c = 8, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 1, .v = 0 }, .c_uv = .{ .u = 1, .v = 1 }, .color = 0xFFFFFFFF },
            // left
            .{ .a = 8, .b = 7, .c = 2, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 0, .v = 0 }, .c_uv = .{ .u = 1, .v = 0 }, .color = 0xFFFFFFFF },
            .{ .a = 8, .b = 2, .c = 1, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 1, .v = 0 }, .c_uv = .{ .u = 1, .v = 1 }, .color = 0xFFFFFFFF },
            // top
            .{ .a = 2, .b = 7, .c = 5, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 0, .v = 0 }, .c_uv = .{ .u = 1, .v = 0 }, .color = 0xFFFFFFFF },
            .{ .a = 2, .b = 5, .c = 3, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 1, .v = 0 }, .c_uv = .{ .u = 1, .v = 1 }, .color = 0xFFFFFFFF },
            // bottom
            .{ .a = 6, .b = 8, .c = 1, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 0, .v = 0 }, .c_uv = .{ .u = 1, .v = 0 }, .color = 0xFFFFFFFF },
            .{ .a = 6, .b = 1, .c = 4, .a_uv = .{ .u = 0, .v = 1 }, .b_uv = .{ .u = 1, .v = 0 }, .c_uv = .{ .u = 1, .v = 1 }, .color = 0xFFFFFFFF },
        };

        return Mesh{
            .obj_file = null,
            .vertices = try std.heap.page_allocator.dupe(Vec3, &vertices),
            .faces = try std.heap.page_allocator.dupe(Face, &faces),
            .rotation = .{ .x = 0, .y = 0, .z = 0 },
            .scale = .{ .x = 1, .y = 1, .z = 1 },
            .translation = .{ .x = 0, .y = 0, .z = 0 },
            .texture = texture,
        };
    }
};
