const std = @import("std");
const impeller_pkg = @import("impeller_zig");

const Backend = enum { glfw, sdl3 };

const ExampleInfo = struct {
    name: []const u8,
    src: []const u8,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const strip = b.option(bool, "strip", "Strip debug symbols") orelse false;

    const os_tag = target.result.os.tag;
    const backend = b.option(Backend, "backend", "Window backend (sdl3, glfw)") orelse .sdl3;
    const exe_suffix = if (os_tag == .windows) ".exe" else "";

    const example_info: ExampleInfo = switch (backend) {
        .glfw => switch (os_tag) {
            .linux => .{ .name = "linux-glfw", .src = "src/linux/linux_glfw.zig" },
            .macos => .{ .name = "macos-glfw", .src = "src/macos/macos_glfw.zig" },
            .windows => .{ .name = "windows-glfw", .src = "src/windows/windows_glfw.zig" },
            else => @panic("Unsupported OS for the GLFW examples"),
        },
        .sdl3 => switch (os_tag) {
            .linux => .{ .name = "linux-sdl3", .src = "src/linux/linux_sdl3.zig" },
            .macos => .{ .name = "macos-sdl3", .src = "src/macos/macos_sdl3.zig" },
            .windows => .{ .name = "windows-sdl3", .src = "src/windows/windows_sdl3.zig" },
            else => @panic("Unsupported OS for the SDL3 examples"),
        },
    };

    const planet_info: ExampleInfo = switch (os_tag) {
        .linux => .{ .name = "linux-planet", .src = "src/linux/linux_planet.zig" },
        .macos => .{ .name = "macos-planet", .src = "src/macos/macos_planet.zig" },
        .windows => .{ .name = "windows-planet", .src = "src/windows/windows_planet.zig" },
        else => @panic("Unsupported OS for the planet example"),
    };

    const liquid_glass_info: ExampleInfo = switch (os_tag) {
        .linux => .{ .name = "linux-liquid-glass", .src = "src/linux/linux_liquid_glass.zig" },
        .macos => .{ .name = "macos-liquid-glass", .src = "src/macos/macos_liquid_glass.zig" },
        .windows => .{ .name = "windows-liquid-glass", .src = "src/windows/windows_liquid_glass.zig" },
        else => @panic("Unsupported OS for the liquid glass example"),
    };

    const impeller_dep = b.dependency("impeller_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const impeller_mod = impeller_dep.module("impeller");

    const sdl3_dep = try b.dependencyLazy("sdl3", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl3_mod = sdl3_dep.module("sdl3");

    const font_mod = b.createModule(.{
        .root_source_file = b.path("src/font.zig"),
        .target = target,
        .optimize = optimize,
    });

    const draw_mod = b.createModule(.{
        .root_source_file = b.path("src/draw.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "impeller", .module = impeller_mod },
            .{ .name = "font", .module = font_mod },
        },
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path(example_info.src),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });

    const planet_mod = b.createModule(.{
        .root_source_file = b.path(planet_info.src),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });

    const liquid_glass_mod = b.createModule(.{
        .root_source_file = b.path(liquid_glass_info.src),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });

    exe_mod.addImport("impeller", impeller_mod);
    exe_mod.addImport("draw", draw_mod);
    switch (backend) {
        .glfw => {
            const glfw_dep = try b.dependencyLazy("glfw_zig", .{
                .target = target,
                .optimize = optimize,
            });
            const glfw_lib = glfw_dep.artifact("glfw");

            const glfw_translate = b.addTranslateC(.{
                .root_source_file = glfw_dep.path("glfw/include/GLFW/glfw3.h"),
                .target = target,
                .optimize = optimize,
            });
            if (os_tag == .linux or os_tag == .windows) {
                glfw_translate.defineCMacro("GLFW_INCLUDE_VULKAN", null);
                glfw_translate.defineCMacro("GLFW_INCLUDE_NONE", null);
                glfw_translate.addIncludePath(glfw_lib.getEmittedIncludeTree());
            }
            exe_mod.addImport("glfw_c", glfw_translate.createModule());
            exe_mod.linkLibrary(glfw_lib);
        },
        .sdl3 => exe_mod.addImport("sdl3", sdl3_mod),
    }

    planet_mod.addImport("impeller", impeller_mod);
    planet_mod.addImport("sdl3", sdl3_mod);
    planet_mod.addAnonymousImport("planet", .{
        .root_source_file = b.path("src/shaders/planet_draw.zig"),
        .imports = &.{
            .{ .name = "impeller", .module = impeller_mod },
        },
    });

    liquid_glass_mod.addImport("impeller", impeller_mod);
    liquid_glass_mod.addImport("sdl3", sdl3_mod);
    liquid_glass_mod.addAnonymousImport("liquid_glass", .{
        .root_source_file = b.path("src/shaders/liquid_glass_draw.zig"),
        .imports = &.{
            .{ .name = "impeller", .module = impeller_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = example_info.name,
        .root_module = exe_mod,
        .use_llvm = if (os_tag == .macos) null else true,
        .use_lld = if (os_tag == .macos) null else true,
    });

    const planet_exe = b.addExecutable(.{
        .name = planet_info.name,
        .root_module = planet_mod,
        .use_llvm = if (os_tag == .macos) null else true,
        .use_lld = if (os_tag == .macos) null else true,
    });

    const liquid_glass_exe = b.addExecutable(.{
        .name = liquid_glass_info.name,
        .root_module = liquid_glass_mod,
        .use_llvm = if (os_tag == .macos) null else true,
        .use_lld = if (os_tag == .macos) null else true,
    });

    exe.each_lib_rpath = false;
    planet_exe.each_lib_rpath = false;
    liquid_glass_exe.each_lib_rpath = false;

    const runtime_install = impeller_pkg.installRuntime(.{
        .compile_step = exe,
        .dependency = impeller_dep,
    });
    b.getInstallStep().dependOn(runtime_install);

    switch (os_tag) {
        .macos => {
            const metal_file = switch (backend) {
                .glfw => "src/macos/macos_glfw_metal.m",
                .sdl3 => "src/macos/macos_sdl3_metal.m",
            };
            exe.root_module.addCSourceFile(.{
                .file = b.path(metal_file),
                .flags = &.{ "-fobjc-arc", "-Wno-deprecated-declarations", "-Wno-unguarded-availability-new" },
                .language = .objective_c,
            });
            exe.root_module.linkFramework("AppKit", .{});
            exe.root_module.linkFramework("Metal", .{});
            exe.root_module.linkFramework("QuartzCore", .{});

            exe.root_module.addRPathSpecial("@executable_path");
        },
        .linux => {
            exe.root_module.linkSystemLibrary("dl", .{});
            exe.root_module.linkSystemLibrary("pthread", .{});
            exe.root_module.linkSystemLibrary("m", .{});

            exe.root_module.addRPathSpecial("$ORIGIN");
        },
        .windows => {},
        else => {},
    }

    const install_exe = b.addInstallArtifact(exe, .{});
    install_exe.step.dependOn(runtime_install);
    b.getInstallStep().dependOn(&install_exe.step);

    const run_cmd = b.addRunFile(b.path(b.fmt("zig-out/bin/{s}{s}", .{ example_info.name, exe_suffix })));
    run_cmd.step.dependOn(&install_exe.step);

    const run_step = b.step("run", "Run the selected window backend example");
    run_step.dependOn(&run_cmd.step);

    switch (os_tag) {
        .macos => {
            planet_exe.root_module.addCSourceFile(.{
                .file = b.path("src/macos/macos_sdl3_metal.m"),
                .flags = &.{ "-fobjc-arc", "-Wno-deprecated-declarations", "-Wno-unguarded-availability-new" },
                .language = .objective_c,
            });
            planet_exe.root_module.linkFramework("AppKit", .{});
            planet_exe.root_module.linkFramework("Metal", .{});
            planet_exe.root_module.linkFramework("QuartzCore", .{});
            planet_exe.root_module.addRPathSpecial("@executable_path");
        },
        .linux => {
            planet_exe.root_module.linkSystemLibrary("dl", .{});
            planet_exe.root_module.linkSystemLibrary("pthread", .{});
            planet_exe.root_module.linkSystemLibrary("m", .{});
            planet_exe.root_module.addRPathSpecial("$ORIGIN");
        },
        .windows => {},
        else => {},
    }

    const install_planet = b.addInstallArtifact(planet_exe, .{});
    install_planet.step.dependOn(runtime_install);
    b.getInstallStep().dependOn(&install_planet.step);

    const run_planet_cmd = b.addRunFile(b.path(b.fmt("zig-out/bin/{s}{s}", .{ planet_info.name, exe_suffix })));
    run_planet_cmd.step.dependOn(&install_planet.step);

    const run_planet_step = b.step("run-planet", "Run the SDL3 planet shader example");
    run_planet_step.dependOn(&run_planet_cmd.step);

    switch (os_tag) {
        .macos => {
            liquid_glass_exe.root_module.addCSourceFile(.{
                .file = b.path("src/macos/macos_sdl3_metal.m"),
                .flags = &.{ "-fobjc-arc", "-Wno-deprecated-declarations", "-Wno-unguarded-availability-new" },
                .language = .objective_c,
            });
            liquid_glass_exe.root_module.linkFramework("AppKit", .{});
            liquid_glass_exe.root_module.linkFramework("Metal", .{});
            liquid_glass_exe.root_module.linkFramework("QuartzCore", .{});
            liquid_glass_exe.root_module.addRPathSpecial("@executable_path");
        },
        .linux => {
            liquid_glass_exe.root_module.linkSystemLibrary("dl", .{});
            liquid_glass_exe.root_module.linkSystemLibrary("pthread", .{});
            liquid_glass_exe.root_module.linkSystemLibrary("m", .{});
            liquid_glass_exe.root_module.addRPathSpecial("$ORIGIN");
        },
        .windows => {},
        else => {},
    }

    const install_liquid_glass = b.addInstallArtifact(liquid_glass_exe, .{});
    install_liquid_glass.step.dependOn(runtime_install);
    b.getInstallStep().dependOn(&install_liquid_glass.step);

    const run_liquid_glass_cmd = b.addRunFile(b.path(b.fmt("zig-out/bin/{s}{s}", .{ liquid_glass_info.name, exe_suffix })));
    run_liquid_glass_cmd.step.dependOn(&install_liquid_glass.step);

    const run_liquid_glass_step = b.step("run-liquid-glass", "Run the SDL3 liquid glass example");
    run_liquid_glass_step.dependOn(&run_liquid_glass_cmd.step);
}
