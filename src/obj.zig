const std = @import("std");
const vec = @import("vec.zig");
const Face = @import("triangle.zig").Face;
const Vec3 = vec.Vec3(f32);

pub const File = struct {
    faces: std.ArrayList(Face),
    vertices: std.ArrayList(Vec3),

    pub fn deinit(self: *File) void {
        self.faces.deinit();
        self.vertices.deinit();
    }
};

pub fn load(allocator: std.mem.Allocator, file_path: []const u8) !File {
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
                .color = 0xFFFFFFFF,
            };
            try faces.append(face);
        }

        line.clearRetainingCapacity();
    }

    return .{
        .faces = faces,
        .vertices = vertices,
    };
}

fn parse_obj_face(line: []const u8) !usize {
    var values = std.mem.splitAny(u8, line, "/");
    return try std.fmt.parseInt(usize, values.next().?, 10);
}
