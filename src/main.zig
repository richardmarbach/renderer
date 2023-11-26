const std = @import("std");
const Display = @import("display.zig").Display;
const draw = @import("draw.zig");
const vec = @import("vec.zig");
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

const CUBE_POINTS = 9 * 9 * 9;
const CubePoints = [CUBE_POINTS]Vec3;
const ProjectedCubePoints = [CUBE_POINTS]Vec2;
var cube_rotation = Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 };

fn update(draw_buffer: *draw.Buffer, cube_points: *CubePoints, projected_points: *ProjectedCubePoints, camera_position: *const Vec3) void {
    cube_rotation.x += 0.01;
    cube_rotation.y += 0.01;
    cube_rotation.z += 0.01;

    for (cube_points, 0..) |point, i| {
        var rotated = point.rotate_x(cube_rotation.x);
        rotated = rotated.rotate_y(cube_rotation.y);
        rotated = rotated.rotate_z(cube_rotation.z);

        rotated.z -= camera_position.z;

        projected_points[i] = project(rotated);
    }

    for (projected_points) |point| {
        draw_buffer.fill_rect(@as(i64, @intFromFloat(point.x + draw_buffer.width_f32() / 2.0)), @as(i64, @intFromFloat(point.y + draw_buffer.height_f32() / 2.0)), 4, 4, 0xFFFFFF00);
    }
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

    var projected_points: ProjectedCubePoints = undefined;
    var cube_points: CubePoints = undefined;
    var point_count: usize = 0;
    var x: f32 = -1.0;
    while (x <= 1.0) : (x += 0.25) {
        var y: f32 = -1.0;
        while (y <= 1.0) : (y += 0.25) {
            var z: f32 = -1.0;
            while (z <= 1.0) : (z += 0.25) {
                cube_points[point_count] = Vec3{ .x = x, .y = y, .z = z };
                point_count += 1;
            }
        }
    }

    var state = State{};
    while (state.is_running) {
        process_input(&state);

        draw.clear(&draw_buffer);

        update(&draw_buffer, &cube_points, &projected_points, &camera_position);

        display.render(draw_buffer.buffer);
    }
}
