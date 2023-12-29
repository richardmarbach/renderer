const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Display = struct {
    width: u32,
    height: u32,
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    buffer_texture: *c.SDL_Texture,

    pub fn init() !Display {
        if (c.SDL_Init(c.SDL_INIT_EVERYTHING) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        errdefer c.SDL_Quit();

        var displayMode: c.SDL_DisplayMode = undefined;
        _ = c.SDL_GetCurrentDisplayMode(0, &displayMode);
        const window_width: u32 = @bitCast(displayMode.w);
        const window_height: u32 = @bitCast(displayMode.h);

        const window = c.SDL_CreateWindow(null, c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, @bitCast(window_width), @bitCast(window_height), c.SDL_WINDOW_BORDERLESS) orelse {
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

        const buffer_texture = c.SDL_CreateTexture(renderer, c.SDL_PIXELFORMAT_ARGB8888, c.SDL_TEXTUREACCESS_STREAMING, @bitCast(window_width), @bitCast(window_height)) orelse {
            c.SDL_Log("Unable to create texture: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        return Display{ .window = window, .renderer = renderer, .buffer_texture = buffer_texture, .width = window_width, .height = window_height };
    }

    pub fn deinit(self: *Display) void {
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }

    pub fn clear(self: *Display) void {
        _ = c.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(self.renderer);
    }

    pub fn render(self: *Display, buffer: []u32) void {
        _ = c.SDL_UpdateTexture(self.buffer_texture, null, buffer.ptr, @bitCast(self.width * @sizeOf(i32)));
        _ = c.SDL_RenderCopy(self.renderer, self.buffer_texture, null, null);

        c.SDL_RenderPresent(self.renderer);
    }

    pub fn aspect_ratio(self: *Display) f32 {
        return @as(f32, @floatFromInt(self.height)) / @as(f32, @floatFromInt(self.width));
    }

    pub fn ticks() u32 {
        return c.SDL_GetTicks();
    }

    pub fn delta_time(previous_frame_time: u32) f32 {
        return @as(f32, @floatFromInt(ticks() - previous_frame_time)) / 1000.0;
    }

    pub fn wait(time: u32) void {
        c.SDL_Delay(time);
    }
};
