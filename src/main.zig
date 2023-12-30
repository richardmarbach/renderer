const std = @import("std");
const Display = @import("display.zig").Display;
const draw = @import("draw.zig");
const vec = @import("vec.zig");
const mesh = @import("mesh.zig");
const Triangle = @import("triangle.zig").Triangle;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Mat4 = @import("matrix.zig").Mat4;
const Vec4 = vec.Vec4(f32);
const Vec3 = vec.Vec3(f32);
const Vec2 = vec.Vec2(f32);

const Light = struct {
    direction: Vec3,
};

const State = struct {
    is_running: bool = true,
    wireframe: bool = true,
    draw_vertices: bool = false,
    fill_triangles: bool = false,
    backface_culling: bool = true,

    projection_matrix: Mat4,
    camera_position: Vec3,

    previous_frame_time: u32 = 0,
    triangles_to_render: std.ArrayList(Triangle),
    draw_buffer: draw.Buffer,

    pub fn init(allocator: std.mem.Allocator, display: *const Display, camera_position: Vec3, projection_matrix: Mat4) !State {
        return .{
            .triangles_to_render = std.ArrayList(Triangle).init(allocator),
            .projection_matrix = projection_matrix,
            .camera_position = camera_position,
            .draw_buffer = try draw.Buffer.init(allocator, display.width, display.height),
        };
    }

    pub fn deinit(self: *State) void {
        self.triangles_to_render.deinit();
        self.draw_buffer.deinit();
    }
};

fn process_input(state: *State) void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_QUIT => {
                state.is_running = false;
            },
            c.SDL_KEYDOWN => {
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => {
                        state.is_running = false;
                    },
                    c.SDLK_1 => {
                        state.wireframe = true;
                        state.draw_vertices = true;
                        state.fill_triangles = false;
                    },
                    c.SDLK_2 => {
                        state.wireframe = true;
                        state.draw_vertices = false;
                        state.fill_triangles = false;
                    },
                    c.SDLK_3 => {
                        state.wireframe = false;
                        state.draw_vertices = false;
                        state.fill_triangles = true;
                    },
                    c.SDLK_4 => {
                        state.wireframe = true;
                        state.draw_vertices = false;
                        state.fill_triangles = true;
                    },
                    c.SDLK_c => {
                        state.backface_culling = true;
                    },
                    c.SDLK_d => {
                        state.backface_culling = false;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

fn update(state: *State, obj_mesh: *mesh.Mesh) !void {
    state.triangles_to_render.clearRetainingCapacity();

    const time_passed = @as(i32, @bitCast(Display.ticks())) - @as(i32, @bitCast(state.previous_frame_time));
    const time_to_wait: i32 = 33 - time_passed;
    if (time_to_wait > 0 and time_to_wait <= 33) {
        Display.wait(@intCast(time_to_wait));
    }
    const delta_time = @as(f32, @floatFromInt(time_passed)) / 1000.0;
    state.previous_frame_time = Display.ticks();

    // obj_mesh.rotation.x += 0.02 * delta_time;
    // obj_mesh.rotation.x += delta_time;
    obj_mesh.rotation = obj_mesh.rotation.add_s(delta_time);
    // obj_mesh.scale.x += 0.2 * delta_time;
    obj_mesh.translation.z = 5;

    const scale = Mat4.init_scale(obj_mesh.scale);
    const translation = Mat4.init_translation(obj_mesh.translation);
    const rotation_x = Mat4.init_rotation_x(obj_mesh.rotation.x);
    const rotation_y = Mat4.init_rotation_y(obj_mesh.rotation.y);
    const rotation_z = Mat4.init_rotation_z(obj_mesh.rotation.z);
    const world = Mat4.init_identity().mul(translation).mul(scale).mul(rotation_x).mul(rotation_y).mul(rotation_z);

    for (obj_mesh.faces) |face| {
        const face_vertices = [3]Vec3{ obj_mesh.vertices[face.a - 1], obj_mesh.vertices[face.b - 1], obj_mesh.vertices[face.c - 1] };

        var transformed_vertices: [3]Vec4 = undefined;

        // Transformation
        for (face_vertices, 0..) |vertex, j| {
            const transformed_vertex = world.mul_vec4(vertex.to_vec4(1.0));
            transformed_vertices[j] = transformed_vertex;
        }

        if (state.backface_culling) {
            const v_a = transformed_vertices[0].to_vec3();
            const v_b = transformed_vertices[1].to_vec3();
            const v_c = transformed_vertices[2].to_vec3();

            const normal = (v_b.sub(v_a).normalize()).cross(v_c.sub(v_a).normalize());
            const camera_ray = state.camera_position.sub(v_a);
            if (normal.dot(camera_ray) < 0.0) {
                continue;
            }
        }

        // Projection
        const depth = (transformed_vertices[0].z + transformed_vertices[1].z + transformed_vertices[2].z);
        var projected_triangle: Triangle = undefined;
        for (transformed_vertices, 0..) |vertex, j| {
            var projected_point: Vec4 = state.projection_matrix.project_vec4(vertex);

            projected_point.x *= state.draw_buffer.width_f32() / 2.0;
            projected_point.y *= state.draw_buffer.height_f32() / 2.0;

            // var projected_point = vertex.to_vec3().project_perspective(640);
            projected_point.x += state.draw_buffer.width_f32() / 2.0;
            projected_point.y += state.draw_buffer.height_f32() / 2.0;

            projected_triangle.points[j] = .{ .x = projected_point.x, .y = projected_point.y };
        }
        projected_triangle.color = face.color;
        projected_triangle.z = depth;

        try state.triangles_to_render.append(projected_triangle);
    }
}

pub fn render(display: *Display, state: *State) void {
    draw.grid(&state.draw_buffer, 0xFF333333);

    std.sort.insertion(Triangle, state.triangles_to_render.items, {}, Triangle.cmp);
    for (state.triangles_to_render.items) |triangle| {
        if (state.fill_triangles) {
            state.draw_buffer.fill_triangle(triangle);
        }
        if (state.wireframe) {
            state.draw_buffer.triangle(triangle);
        }

        if (state.draw_vertices) {
            state.draw_buffer.fill_rect_point(triangle.points[0], 3, 3, 0xFFFF0000);
            state.draw_buffer.fill_rect_point(triangle.points[1], 3, 3, 0xFFFF0000);
            state.draw_buffer.fill_rect_point(triangle.points[2], 3, 3, 0xFFFF0000);
        }
    }

    display.render(state.draw_buffer.buffer);
    draw.clear(&state.draw_buffer);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var display = try Display.init();
    defer display.deinit();

    var obj_mesh = try mesh.Mesh.load_obj(allocator, "assets/cube.obj");

    const camera_position: Vec3 = Vec3{ .x = 0.0, .y = 0.0, .z = -5.0 };
    const fov = 60.0 * (std.math.pi / 180.0);
    const projection_matrix = Mat4.init_perspective(fov, display.aspect_ratio(), 0.1, 100.0);
    var state = try State.init(allocator, &display, camera_position, projection_matrix);
    defer state.deinit();
    while (state.is_running) {
        process_input(&state);

        try update(&state, &obj_mesh);

        render(&display, &state);
    }
}

test {
    std.testing.refAllDecls(@This());
}
