const impeller = @import("impeller");
const draw = @import("draw");
const sdl3 = @import("sdl3");

const ExampleError = error{
    VulkanInfoUnavailable,
    PresentationUnsupported,
};

pub fn main() !void {
    defer sdl3.shutdown();

    try sdl3.hints.setWithPriority(.video_driver, "x11", .override);

    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    const window_size = try initialWindowSize();
    const window = try sdl3.video.Window.init("impeller-zig Vulkan", window_size.width, window_size.height, .{
        .vulkan = true,
        .resizable = true,
        .high_pixel_density = true,
    });
    defer window.deinit();

    var context = try impeller.Context.initVulkan(.{
        .user_data = null,
        .proc_address_callback = VulkanProcResolver.resolve,
        .enable_vulkan_validation = false,
    });
    defer context.deinit();

    const vulkan_info = context.vulkanInfo() orelse return ExampleError.VulkanInfoUnavailable;

    if (!sdl3.vulkan.getPresentationSupport(
        @ptrCast(vulkan_info.vk_instance),
        @ptrCast(vulkan_info.vk_physical_device),
        vulkan_info.graphics_queue_family_index,
    )) {
        return ExampleError.PresentationUnsupported;
    }

    const vulkan_surface = try sdl3.vulkan.Surface.init(
        window,
        @ptrCast(vulkan_info.vk_instance),
        null,
    );

    var swapchain = try impeller.VulkanSwapchain.init(context, @ptrCast(vulkan_surface.surface));
    defer swapchain.deinit();

    var scene = try draw.createScene(context, "Linux SDL3");
    defer scene.deinit();

    var quit = false;
    while (!quit) {
        while (sdl3.events.poll()) |event| {
            switch (event) {
                .quit, .terminating => quit = true,
                .key_down => |key| {
                    if (key.key == .escape) {
                        quit = true;
                    }
                },
                else => {},
            }
        }

        var width: c_int = 0;
        var height: c_int = 0;
        _ = sdl3.c.SDL_GetWindowSizeInPixels(window.value, &width, &height);
        if (width <= 0 or height <= 0) {
            continue;
        }

        var surface = swapchain.acquireNextSurface() catch continue;
        defer surface.deinit();

        try draw.drawScene(surface, scene, .{
            .width = @intCast(width),
            .height = @intCast(height),
        });
        try surface.present();
    }
}

const WindowSize = struct {
    width: usize,
    height: usize,
};

fn initialWindowSize() !WindowSize {
    return .{
        .width = draw.canvas_width,
        .height = draw.canvas_height,
    };
}

const VulkanProcResolver = struct {
    fn resolve(instance: ?*anyopaque, proc_name: [*c]const u8, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
        _ = user_data;
        const GetProcAddr = *const fn (?*anyopaque, [*c]const u8) callconv(.c) ?*anyopaque;
        const get_proc_addr: GetProcAddr = @ptrCast(sdl3.vulkan.getVkGetInstanceProcAddr() catch return null);
        return get_proc_addr(instance, proc_name);
    }
};
