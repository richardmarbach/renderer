const std = @import("std");
const vec = @import("vec.zig");
const Face = @import("triangle.zig").Face;
const Vec3 = vec.Vec3(f32);
const Tex2 = @import("texture.zig").Tex2;

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

    var tex_vertices = std.ArrayList(Tex2).init(allocator);
    defer tex_vertices.deinit();

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
        } else if (std.mem.eql(u8, line_type, "vt")) {
            const tex = Tex2{
                .u = try std.fmt.parseFloat(f32, values.next().?),
                .v = 1 - try std.fmt.parseFloat(f32, values.next().?),
            };
            try tex_vertices.append(tex);
        } else if (std.mem.eql(u8, line_type, "f")) {
            const a = try parse_obj_face(values.next().?);
            const b = try parse_obj_face(values.next().?);
            const c = try parse_obj_face(values.next().?);

            const face = Face{
                .a = a.v,
                .b = b.v,
                .c = c.v,
                .a_uv = tex_vertices.items[a.t - 1],
                .b_uv = tex_vertices.items[b.t - 1],
                .c_uv = tex_vertices.items[c.t - 1],
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

const FaceValue = struct { v: usize, t: usize, n: usize };
fn parse_obj_face(line: []const u8) !FaceValue {
    var values = std.mem.splitAny(u8, line, "/");
    return .{
        .v = try std.fmt.parseInt(usize, values.next().?, 10),
        .t = try std.fmt.parseInt(usize, values.next().?, 10),
        .n = try std.fmt.parseInt(usize, values.next().?, 10),
    };
}
