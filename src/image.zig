const tex = @import("texture.zig");
const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL_image.h");
});

pub const SDLImage = struct {
    width: usize,
    height: usize,
    pixels: []const u32,

    surface: *c.SDL_Surface,

    pub fn load(allocator: std.mem.Allocator, path: []const u8) !*SDLImage {
        const surface = c.IMG_Load(path.ptr) orelse {
            return error.SDLImageLoadError;
        };

        const converted = c.SDL_ConvertSurfaceFormat(surface, c.SDL_PIXELFORMAT_ARGB8888, 0);
        errdefer c.SDL_FreeSurface(converted);

        c.SDL_FreeSurface(surface);

        const pixels = converted.*.pixels orelse {
            return error.SDLImageLoadError;
        };

        const width: usize = @intCast(converted.*.w);
        const height: usize = @intCast(converted.*.h);

        var image = try allocator.create(SDLImage);
        image.surface = converted;
        image.width = width;
        image.height = height;
        image.pixels = @as([*]u32, @ptrCast(@alignCast(pixels)))[0..(width * height)];

        return image;
    }

    pub fn deinit(self: *SDLImage) void {
        c.SDL_FreeSurface(self.surface);
    }
};
