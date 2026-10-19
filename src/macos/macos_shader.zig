const impeller = @import("impeller");
const draw = @import("draw");
const sdl3 = @import("sdl3");

extern fn macosSdl3ConfigureMetalLayer(layer: ?*anyopaque) ?*anyopaque;
extern fn macosSdl3AcquireNextDrawable(layer: ?*anyopaque, width: f64, height: f64) ?*anyopaque;
extern fn macosSdl3ReleaseDrawable(drawable: ?*anyopaque) void;

const ExampleError = error{
    MetalViewCreateFailed,
    MetalLayerUnavailable,
};

pub fn main() !void {
    defer sdl3.shutdown();

    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    const window = try sdl3.video.Window.init("Impeller shader lab · Metal", draw.canvas_width, draw.canvas_height, .{
        .metal = true,
        .high_pixel_density = true,
        .resizable = true,
    });
    defer window.deinit();

    const metal_view = sdl3.c.SDL_Metal_CreateView(window.value) orelse return ExampleError.MetalViewCreateFailed;
    defer sdl3.c.SDL_Metal_DestroyView(metal_view);

    const metal_layer = macosSdl3ConfigureMetalLayer(sdl3.c.SDL_Metal_GetLayer(metal_view)) orelse {
        return ExampleError.MetalLayerUnavailable;
    };

    var context = try impeller.Context.initMetal();
    defer context.deinit();

    var scene = try draw.createScene(context, "MACOS / METAL");
    defer scene.deinit();

    var quit = false;
    while (!quit) {
        while (sdl3.events.poll()) |event| {
            switch (event) {
                .quit, .terminating => quit = true,
                .key_down => |key| if (key.key == .escape) {
                    quit = true;
                },
                else => {},
            }
        }

        var width: c_int = 0;
        var height: c_int = 0;
        _ = sdl3.c.SDL_GetWindowSizeInPixels(window.value, &width, &height);
        if (width <= 0 or height <= 0) continue;

        const drawable = macosSdl3AcquireNextDrawable(
            metal_layer,
            @floatFromInt(width),
            @floatFromInt(height),
        ) orelse continue;
        defer macosSdl3ReleaseDrawable(drawable);

        var surface = try impeller.Surface.wrapMetalDrawable(context, drawable);
        defer surface.deinit();

        try draw.drawScene(surface, context, scene, .{
            .width = @intCast(width),
            .height = @intCast(height),
        }, elapsedSeconds());
        try surface.present();
    }
}

fn elapsedSeconds() f32 {
    return @as(f32, @floatFromInt(sdl3.c.SDL_GetTicks())) / 1000.0;
}
