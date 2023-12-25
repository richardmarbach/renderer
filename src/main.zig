const std = @import("std");
const Display = @import("display.zig").Display;
const draw = @import("draw.zig");
const vec = @import("vec.zig");
const mesh = @import("mesh.zig");
const Triangle = @import("triangle.zig").Triangle;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const Vec3 = vec.Vec3(f32);
const Vec2 = vec.Vec2(f32);

pub const Camera = struct {
    position: Vec3(f32),
    rotation: Vec3(f32),
    fov_angle: f32,
};

const State = struct {
    is_running: bool = true,
};

fn process_input(state: *State) void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_QUIT => {
                state.is_running = false;
            },
            c.SDL_KEYDOWN => {
                if (event.key.keysym.sym == c.SDLK_ESCAPE) {
                    state.is_running = false;
                }
            },
            else => {},
        }
    }
}

const FOV_FACTOR: f32 = 640;

fn project(vec3: Vec3) Vec2 {
    return Vec2{ .x = (vec3.x * FOV_FACTOR) / vec3.z, .y = (vec3.y * FOV_FACTOR) / vec3.z };
}

var previous_frame_time: u32 = 0.0;
var triangles_to_render: std.ArrayList(Triangle) = undefined;

fn update(draw_buffer: *draw.Buffer, camera_position: *const Vec3, obj_mesh: *mesh.Mesh) !void {
    triangles_to_render.clearRetainingCapacity();

    const time_passed = @as(i32, @bitCast(Display.ticks())) - @as(i32, @bitCast(previous_frame_time));
    const time_to_wait: i32 = 33 - time_passed;
    if (time_to_wait > 0 and time_to_wait <= 33) {
        Display.wait(@intCast(time_to_wait));
    }
    const delta_time = @as(f32, @floatFromInt(time_passed)) / 1000.0;
    previous_frame_time = Display.ticks();

    obj_mesh.rotation = obj_mesh.rotation.add_s(1.0 * delta_time);
    // obj_mesh.rotation.x += 1.0 * delta_time;

    for (obj_mesh.faces) |face| {
        var face_vertices = [3]Vec3{ obj_mesh.vertices[face.a - 1], obj_mesh.vertices[face.b - 1], obj_mesh.vertices[face.c - 1] };

        // Transformation
        for (face_vertices, 0..) |vertex, j| {
            face_vertices[j] = vertex
                .rotate_x(obj_mesh.rotation.x)
                .rotate_y(obj_mesh.rotation.y)
                .rotate_z(obj_mesh.rotation.z);
            face_vertices[j].z += 5.0;
        }

        // Backface culling
        const v_a = face_vertices[0];
        const v_b = face_vertices[1];
        const v_c = face_vertices[2];

        const normal = (v_b.sub(v_a)).cross(v_c.sub(v_a));
        const camera_ray = camera_position.sub(v_a);
        if (normal.dot(camera_ray) < 0.0) {
            continue;
        }

        // Projection
        var projected_triangle: Triangle = undefined;
        for (face_vertices, 0..) |vertex, j| {
            var projected_point = project(vertex);
            projected_point.x += draw_buffer.width_f32() / 2.0;
            projected_point.y += draw_buffer.height_f32() / 2.0;

            projected_triangle.points[j] = projected_point;
        }

        try triangles_to_render.append(projected_triangle);
    }

    draw.grid(draw_buffer);

    for (triangles_to_render.items) |triangle| {
        draw_buffer.fill_rect(@as(i64, @intFromFloat(triangle.points[0].x)), @as(i64, @intFromFloat(triangle.points[0].y)), 3, 3, 0xFFFFFF00);
        draw_buffer.fill_rect(@as(i64, @intFromFloat(triangle.points[1].x)), @as(i64, @intFromFloat(triangle.points[1].y)), 3, 3, 0xFFFFFF00);
        draw_buffer.fill_rect(@as(i64, @intFromFloat(triangle.points[2].x)), @as(i64, @intFromFloat(triangle.points[2].y)), 3, 3, 0xFFFFFF00);

        draw_buffer.triangle(@as(i64, @intFromFloat(triangle.points[0].x)), @as(i64, @intFromFloat(triangle.points[0].y)), @as(i64, @intFromFloat(triangle.points[1].x)), @as(i64, @intFromFloat(triangle.points[1].y)), @as(i64, @intFromFloat(triangle.points[2].x)), @as(i64, @intFromFloat(triangle.points[2].y)), 0xFF00FF00);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    triangles_to_render = std.ArrayList(Triangle).init(allocator);
    defer triangles_to_render.deinit();

    var display = try Display.init();
    defer display.deinit();

    var draw_buffer = try draw.Buffer.init(allocator, display.width, display.height);
    defer draw_buffer.deinit();

    const camera_position: Vec3 = Vec3{ .x = 0.0, .y = 0.0, .z = -5.0 };

    var obj_mesh = try mesh.Mesh.load_obj(allocator, "assets/cube.obj");

    var state = State{};
    while (state.is_running) {
        process_input(&state);

        draw.clear(&draw_buffer);

        try update(&draw_buffer, &camera_position, &obj_mesh);

        display.render(draw_buffer.buffer);
    }
}

test {
    std.testing.refAllDecls(@This());
}
