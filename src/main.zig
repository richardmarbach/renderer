const std = @import("std");
const Display = @import("display.zig").Display;
const DrawBuffer = @import("draw_buffer.zig").DrawBuffer;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

var isRunning: bool = true;

pub fn processInput() void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_QUIT => {
                isRunning = false;
            },
            c.SDL_KEYDOWN => {
                if (event.key.keysym.sym == c.SDLK_ESCAPE) {
                    isRunning = false;
                }
            },
            else => {},
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var display = try Display.init();
    defer display.deinit();

    var draw_buffer = try DrawBuffer.init(allocator, display.width, display.height);
    defer draw_buffer.deinit();

    while (isRunning) {
        processInput();

        display.clear();

        draw_buffer.draw_grid();
        draw_buffer.draw_rect(200, 300, 50, 100, 0xFFFFFF00);

        display.draw_buffer(draw_buffer.buffer);
        draw_buffer.clear();

        display.render();
    }
}
