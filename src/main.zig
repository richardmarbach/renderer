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

pub const Camera = struct {
    position: Vec3(f32),
    rotation: Vec3(f32),
    fov_angle: f32,
};

const ProjectionType = enum {
    orthographic,
    perspective,

    pub fn fov_factor(comptime self: ProjectionType) f32 {
        return switch (self) {
            .orthographic => 128,
            .perspective => 640,
        };
    }
};

const State = struct {
    is_running: bool = true,
    wireframe: bool = true,
    draw_vertices: bool = false,
    fill_triangles: bool = true,
    backface_culling: bool = true,
    projection_type: ProjectionType = .perspective,

    previous_frame_time: u32 = 0,
    triangles_to_render: std.ArrayList(Triangle),

    pub fn init(allocator: std.mem.Allocator) State {
        return .{
            .triangles_to_render = std.ArrayList(Triangle).init(allocator),
        };
    }

    pub fn deinit(self: *State) void {
        self.triangles_to_render.deinit();
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
                    c.SDLK_p => {
                        state.projection_type = .perspective;
                    },
                    c.SDLK_o => {
                        state.projection_type = .orthographic;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

fn update(state: *State, draw_buffer: *draw.Buffer, camera_position: *const Vec3, obj_mesh: *mesh.Mesh) !void {
    state.triangles_to_render.clearRetainingCapacity();

    const time_passed = @as(i32, @bitCast(Display.ticks())) - @as(i32, @bitCast(state.previous_frame_time));
    const time_to_wait: i32 = 33 - time_passed;
    if (time_to_wait > 0 and time_to_wait <= 33) {
        Display.wait(@intCast(time_to_wait));
    }
    const delta_time = @as(f32, @floatFromInt(time_passed)) / 1000.0;
    state.previous_frame_time = Display.ticks();

    obj_mesh.rotation = obj_mesh.rotation.add_s(1.0 * delta_time);
    // obj_mesh.rotation.x += 1.0 * delta_time;

    obj_mesh.scale.x += 0.002;
    obj_mesh.scale.y += 0.002;
    obj_mesh.scale.z += 0.002;

    const scale = Mat4.init_scale(obj_mesh.scale);

    for (obj_mesh.faces) |face| {
        const face_vertices = [3]Vec3{ obj_mesh.vertices[face.a - 1], obj_mesh.vertices[face.b - 1], obj_mesh.vertices[face.c - 1] };

        var transformed_vertices: [3]Vec3 = undefined;

        // Transformation
        for (face_vertices, 0..) |vertex, j| {
            var transformed_vertex = vertex.to_vec4(1.0);
            transformed_vertex = scale.mul_vec4(transformed_vertex);
            transformed_vertex.z += 5.0;

            transformed_vertices[j] = transformed_vertex.to_vec3();
        }

        if (state.backface_culling) {
            const v_a = transformed_vertices[0];
            const v_b = transformed_vertices[1];
            const v_c = transformed_vertices[2];

            const normal = (v_b.sub(v_a).normalize()).cross(v_c.sub(v_a).normalize());
            const camera_ray = camera_position.sub(v_a);
            if (normal.dot(camera_ray) < 0.0) {
                continue;
            }
        }

        // Projection
        const depth = (transformed_vertices[0].z + transformed_vertices[1].z + transformed_vertices[2].z);
        var projected_triangle: Triangle = undefined;
        for (transformed_vertices, 0..) |vertex, j| {
            var projected_point: Vec2 = switch (state.projection_type) {
                .orthographic => vertex.project_orthographic(ProjectionType.orthographic.fov_factor()),
                .perspective => vertex.project_perspective(ProjectionType.perspective.fov_factor()),
            };

            projected_point.x += draw_buffer.width_f32() / 2.0;
            projected_point.y += draw_buffer.height_f32() / 2.0;

            projected_triangle.points[j] = projected_point;
        }
        projected_triangle.color = face.color;
        projected_triangle.z = depth;

        try state.triangles_to_render.append(projected_triangle);
    }
}

pub fn render(display: *Display, state: *State, draw_buffer: *draw.Buffer) void {
    draw.grid(draw_buffer, 0xFF333333);

    std.sort.insertion(Triangle, state.triangles_to_render.items, {}, Triangle.cmp);
    for (state.triangles_to_render.items) |triangle| {
        if (state.fill_triangles) {
            draw_buffer.fill_triangle(triangle);
        }
        if (state.wireframe) {
            draw_buffer.triangle(triangle);
        }

        if (state.draw_vertices) {
            draw_buffer.fill_rect_point(triangle.points[0], 3, 3, 0xFFFF0000);
            draw_buffer.fill_rect_point(triangle.points[1], 3, 3, 0xFFFF0000);
            draw_buffer.fill_rect_point(triangle.points[2], 3, 3, 0xFFFF0000);
        }
    }

    display.render(draw_buffer.buffer);
    draw.clear(draw_buffer);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var display = try Display.init();
    defer display.deinit();

    var draw_buffer = try draw.Buffer.init(allocator, display.width, display.height);
    defer draw_buffer.deinit();

    const camera_position: Vec3 = Vec3{ .x = 0.0, .y = 0.0, .z = -5.0 };
    var obj_mesh = try mesh.Mesh.load_obj(allocator, "assets/cube.obj");

    var state = State.init(allocator);
    defer state.deinit();
    while (state.is_running) {
        process_input(&state);

        try update(&state, &draw_buffer, &camera_position, &obj_mesh);

        render(&display, &state, &draw_buffer);
    }
}

test {
    std.testing.refAllDecls(@This());
}
