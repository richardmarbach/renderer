const std = @import("std");
const vec = @import("vec.zig");
const Face = @import("triangle.zig").Face;
const Vec3 = vec.Vec3(f32);

pub const Mesh = struct {
    vertices: []Vec3,
    faces: []Face,
    rotation: Vec3,
    scale: Vec3,
    translation: Vec3,

    pub fn load_obj(allocator: std.mem.Allocator, file_path: []const u8) !Mesh {
        var file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        var buffered = std.io.bufferedReader(file.reader());
        var reader = buffered.reader();

        var line = std.ArrayList(u8).init(allocator);
        defer line.deinit();
        var vertices = std.ArrayList(Vec3).init(allocator);
        var faces = std.ArrayList(Face).init(allocator);

        while (true) {
            reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            if (line.items.len < 1) {
                line.clearRetainingCapacity();
                continue;
            }

            var values = std.mem.splitAny(u8, line.items, " ");
            const line_type = values.next().?;
            if (std.mem.eql(u8, line_type, "v")) {
                const vertex = Vec3{
                    .x = try std.fmt.parseFloat(f32, values.next().?),
                    .y = try std.fmt.parseFloat(f32, values.next().?),
                    .z = try std.fmt.parseFloat(f32, values.next().?),
                };
                try vertices.append(vertex);
            } else if (std.mem.eql(u8, line_type, "f")) {
                const face = Face{
                    .a = try parse_obj_face(values.next().?),
                    .b = try parse_obj_face(values.next().?),
                    .c = try parse_obj_face(values.next().?),
                    .color = 0xFF555555,
                };
                try faces.append(face);
            }

            line.clearRetainingCapacity();
        }

        return Mesh{
            .vertices = vertices.items,
            .faces = faces.items,
            .rotation = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
            .scale = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
            .translation = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
        };
    }
};

fn parse_obj_face(line: []const u8) !usize {
    var values = std.mem.splitAny(u8, line, "/");
    return try std.fmt.parseInt(usize, values.next().?, 10);
}
