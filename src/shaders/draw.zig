const std = @import("std");
const impeller = @import("impeller");

const shader_bytes = @embedFile("planet.iplr");

pub const canvas_width = 960;
pub const canvas_height = 640;

const ShaderUniforms = extern struct {
    resolution: [2]f32,
    time: f32,
};

pub const SurfaceSize = struct {
    width: usize,
    height: usize,
};

pub const Scene = struct {
    fragment_program: impeller.FragmentProgram,

    pub fn deinit(self: *Scene) void {
        self.fragment_program.deinit();
    }
};

pub fn createScene(context: impeller.Context, platform_name: []const u8) !Scene {
    _ = context;
    _ = platform_name;
    return .{
        .fragment_program = try impeller.FragmentProgram.initBorrowed(shader_bytes),
    };
}

pub fn drawScene(
    surface: impeller.Surface,
    context: impeller.Context,
    scene: Scene,
    surface_size: SurfaceSize,
    elapsed_seconds: f32,
) !void {
    std.debug.assert(surface_size.width > 0);
    std.debug.assert(surface_size.height > 0);

    const width: f32 = @floatFromInt(surface_size.width);
    const height: f32 = @floatFromInt(surface_size.height);
    const uniforms = ShaderUniforms{
        .resolution = .{ width, height },
        .time = elapsed_seconds,
    };

    var color_source = try impeller.ColorSource.initFragmentProgram(
        std.heap.page_allocator,
        context,
        scene.fragment_program,
        &.{},
        std.mem.asBytes(&uniforms),
    );
    defer color_source.deinit();

    var paint = try impeller.Paint.init();
    defer paint.deinit();
    paint.setColorSource(color_source);

    var builder = try impeller.DisplayListBuilder.init(impeller.rect(0.0, 0.0, width, height));
    defer builder.deinit();

    builder.drawRect(impeller.rect(0.0, 0.0, width, height), paint);

    var display_list = try builder.build();
    defer display_list.deinit();
    try surface.draw(display_list);
}
