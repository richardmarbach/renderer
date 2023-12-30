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
    pub fn init(direction: Vec3) Light {
        return .{ .direction = direction.normalize() };
    }

    pub fn apply_intensity(color: u32, intensity: f32) u32 {
        const f = std.math.clamp(intensity, 0.0, 1.0);
        const a: u32 = (color & 0xFF000000);
        const r: u32 = @intFromFloat(@as(f32, @floatFromInt(color & 0x00FF0000)) * f);
        const g: u32 = @intFromFloat(@as(f32, @floatFromInt(color & 0x0000FF00)) * f);
        const b: u32 = @intFromFloat(@as(f32, @floatFromInt(color & 0x000000FF)) * f);

        return a | (r & 0x00FF0000) | (g & 0x0000FF00) | (b & 0x000000FF);
    }
};

const World = struct {
    is_running: bool = true,
    wireframe: bool = true,
    draw_vertices: bool = false,
    fill_triangles: bool = false,
    backface_culling: bool = true,

    projection_matrix: Mat4,
    camera_position: Vec3,
    light: Light,

    previous_frame_time: u32 = 0,

    allocator: std.mem.Allocator,
    triangles_to_render: std.ArrayList(Triangle),
    draw_buffer: draw.Buffer,
    objs: std.ArrayList(mesh.Mesh),

    pub fn init(allocator: std.mem.Allocator, display: *const Display, camera_position: Vec3, projection_matrix: Mat4, light: Light) !World {
        return .{
            .allocator = allocator,
            .triangles_to_render = std.ArrayList(Triangle).init(allocator),
            .projection_matrix = projection_matrix,
            .camera_position = camera_position,
            .light = light,
            .draw_buffer = try draw.Buffer.init(allocator, display.width, display.height),
            .objs = std.ArrayList(mesh.Mesh).init(allocator),
        };
    }

    pub fn load_obj(self: *World, file_path: []const u8) !void {
        const obj_mesh = try mesh.Mesh.load_obj(self.allocator, file_path);
        try self.objs.append(obj_mesh);
    }

    pub fn deinit(self: *World) void {
        self.triangles_to_render.deinit();
        self.draw_buffer.deinit();
        self.objs.deinit();
    }

    fn process_input(self: *World) void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    self.is_running = false;
                },
                c.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_ESCAPE => {
                            self.is_running = false;
                        },
                        c.SDLK_1 => {
                            self.wireframe = true;
                            self.draw_vertices = true;
                            self.fill_triangles = false;
                        },
                        c.SDLK_2 => {
                            self.wireframe = true;
                            self.draw_vertices = false;
                            self.fill_triangles = false;
                        },
                        c.SDLK_3 => {
                            self.wireframe = false;
                            self.draw_vertices = false;
                            self.fill_triangles = true;
                        },
                        c.SDLK_4 => {
                            self.wireframe = true;
                            self.draw_vertices = false;
                            self.fill_triangles = true;
                        },
                        c.SDLK_c => {
                            self.backface_culling = true;
                        },
                        c.SDLK_d => {
                            self.backface_culling = false;
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }
    }

    fn update(self: *World) !void {
        self.triangles_to_render.clearRetainingCapacity();

        const time_passed = @as(i32, @bitCast(Display.ticks())) - @as(i32, @bitCast(self.previous_frame_time));
        const time_to_wait: i32 = 33 - time_passed;
        if (time_to_wait > 0 and time_to_wait <= 33) {
            Display.wait(@intCast(time_to_wait));
        }
        const delta_time = @as(f32, @floatFromInt(time_passed)) / 1000.0;
        self.previous_frame_time = Display.ticks();

        var obj_mesh = &self.objs.items[0];
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

            const v_a = transformed_vertices[0].to_vec3();
            const v_b = transformed_vertices[1].to_vec3();
            const v_c = transformed_vertices[2].to_vec3();

            const normal = v_b.sub(v_a).cross(v_c.sub(v_a)).normalize();

            if (self.backface_culling) {
                const camera_ray = self.camera_position.sub(v_a);
                if (normal.dot(camera_ray) < 0.0) {
                    continue;
                }
            }

            // Lighting
            var color = face.color;
            const intensity = -normal.dot(self.light.direction);
            color = Light.apply_intensity(color, intensity);

            // Projection
            const depth = (transformed_vertices[0].z + transformed_vertices[1].z + transformed_vertices[2].z);
            var projected_triangle: Triangle = undefined;
            for (transformed_vertices, 0..) |vertex, j| {
                var projected_point: Vec4 = self.projection_matrix.project_vec4(vertex);

                projected_point.x *= self.draw_buffer.width_f32() / 2.0;
                projected_point.y *= self.draw_buffer.height_f32() / 2.0;

                projected_point.y *= -1;

                // var projected_point = vertex.to_vec3().project_perspective(640);
                projected_point.x += self.draw_buffer.width_f32() / 2.0;
                projected_point.y += self.draw_buffer.height_f32() / 2.0;

                projected_triangle.points[j] = .{ .x = projected_point.x, .y = projected_point.y };
            }
            projected_triangle.color = color;
            projected_triangle.z = depth;

            try self.triangles_to_render.append(projected_triangle);
        }
    }

    pub fn render(self: *World, display: *Display) void {
        draw.grid(&self.draw_buffer, 0xFF333333);

        std.sort.insertion(Triangle, self.triangles_to_render.items, {}, Triangle.cmp);
        for (self.triangles_to_render.items) |triangle| {
            if (self.fill_triangles) {
                self.draw_buffer.fill_triangle(triangle);
            }
            if (self.wireframe) {
                self.draw_buffer.triangle(triangle);
            }

            if (self.draw_vertices) {
                self.draw_buffer.fill_rect_point(triangle.points[0], 3, 3, 0xFFFF0000);
                self.draw_buffer.fill_rect_point(triangle.points[1], 3, 3, 0xFFFF0000);
                self.draw_buffer.fill_rect_point(triangle.points[2], 3, 3, 0xFFFF0000);
            }
        }

        display.render(self.draw_buffer.buffer);
        draw.clear(&self.draw_buffer);
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var display = try Display.init();
    defer display.deinit();

    const light = Light.init(Vec3.init(0.0, 0.0, 1.0));
    const camera_position: Vec3 = Vec3.init(0.0, 0.0, -5.0);
    const fov = 60.0 * (std.math.pi / 180.0);
    const projection_matrix = Mat4.init_perspective(fov, display.aspect_ratio(), 0.1, 100.0);
    var world = try World.init(allocator, &display, camera_position, projection_matrix, light);
    defer world.deinit();

    try world.load_obj("assets/cube.obj");

    while (world.is_running) {
        world.process_input();

        try world.update();

        world.render(&display);
    }
}

test {
    std.testing.refAllDecls(@This());
}
