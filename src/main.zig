const std = @import("std");
const Display = @import("display.zig").Display;
const DrawBuffer = @import("draw_buffer.zig").DrawBuffer;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

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

fn update(draw_buffer: *DrawBuffer) void {
    draw_buffer.draw_grid();
    draw_buffer.draw_rect(200, 300, 50, 100, 0xFFFFFF00);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var display = try Display.init();
    defer display.deinit();

    var draw_buffer = try DrawBuffer.init(allocator, display.width, display.height);
    defer draw_buffer.deinit();

    var state = State{};
    while (state.is_running) {
        process_input(&state);

        draw_buffer.clear();
        display.clear();

        update(&draw_buffer);

        display.render(draw_buffer.buffer);
    }
}
