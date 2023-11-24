const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

var isRunning: bool = true;
var window_width: i32 = 800;
var window_height: i32 = 600;

const Window = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,

    allocator: std.mem.Allocator,
    color_buffer: []u32,

    pub fn init(allocator: std.mem.Allocator) !Window {
        if (c.SDL_Init(c.SDL_INIT_EVERYTHING) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        errdefer c.SDL_Quit();

        var displayMode: c.SDL_DisplayMode = undefined;
        _ = c.SDL_GetCurrentDisplayMode(0, &displayMode);
        window_width = displayMode.w;
        window_height = displayMode.h;

        const window = c.SDL_CreateWindow(null, c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, window_width, window_height, c.SDL_WINDOW_BORDERLESS) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyWindow(window);

        const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyRenderer(renderer);

        _ = c.SDL_SetWindowFullscreen(window, c.SDL_WINDOW_FULLSCREEN);

        return Window{
            .window = window,
            .renderer = renderer,
            .color_buffer = try allocator.alloc(u32, @as(u32, @bitCast(window_width * window_height))),
            .allocator = allocator,
        };
    }

    pub fn clear_color_buffer(self: *Window, color: u32) void {
        @memset(self.color_buffer, color);
    }

    pub fn deinit(self: *Window) void {
        self.allocator.free(self.color_buffer);
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

    const color_buffer_texture = c.SDL_CreateTexture(window.renderer, c.SDL_PIXELFORMAT_ARGB8888, c.SDL_TEXTUREACCESS_STREAMING, window_width, window_height) orelse {
        c.SDL_Log("Unable to create texture: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    while (isRunning) {
        processInput();

        _ = c.SDL_SetRenderDrawColor(window.renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(window.renderer);

        window.clear_color_buffer(0xFFFFFF00);

        _ = c.SDL_UpdateTexture(color_buffer_texture, null, window.color_buffer.ptr, window_width * @sizeOf(u32));
        _ = c.SDL_RenderCopy(window.renderer, color_buffer_texture, null, null);

        c.SDL_RenderPresent(window.renderer);
    }
}
