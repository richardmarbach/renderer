const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

var isRunning: bool = true;
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;

const Window = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,

    allocator: std.mem.Allocator,
    colorBuffer: []u32,

    pub fn init(allocator: std.mem.Allocator) !Window {
        if (c.SDL_Init(c.SDL_INIT_EVERYTHING) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        errdefer c.SDL_Quit();

        const window = c.SDL_CreateWindow(null, c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, c.SDL_WINDOW_BORDERLESS) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyWindow(window);

        const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyRenderer(renderer);

        return Window{
            .window = window,
            .renderer = renderer,
            .colorBuffer = try allocator.alloc(u32, WINDOW_WIDTH * WINDOW_HEIGHT),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Window) void {
        self.allocator.free(self.colorBuffer);
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }
};

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

    var window = try Window.init(arena.allocator());
    defer window.deinit();

    while (isRunning) {
        processInput();

        _ = c.SDL_SetRenderDrawColor(window.renderer, 255, 0, 0, 255);
        _ = c.SDL_RenderClear(window.renderer);

        c.SDL_RenderPresent(window.renderer);
    }
}
