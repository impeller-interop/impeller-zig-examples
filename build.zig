const std = @import("std");
const impeller_pkg = @import("impeller_zig");

const ExampleInfo = struct {
    name: []const u8,
    src: []const u8,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const strip = b.option(bool, "strip", "Strip debug symbols") orelse false;

    const os_tag = target.result.os.tag;

    const example_info: ExampleInfo = switch (os_tag) {
        .linux => .{ .name = "linux-glfw", .src = "src/linux/linux_glfw.zig" },
        .macos => .{ .name = "macos-glfw", .src = "src/macos/macos_glfw.zig" },
        .windows => .{ .name = "windows-glfw", .src = "src/windows/windows_glfw.zig" },
        else => @panic("Unsupported OS for the GLFW examples"),
    };

    const shader_info: ExampleInfo = switch (os_tag) {
        .linux => .{ .name = "linux-shader", .src = "src/linux/linux_shader.zig" },
        .macos => .{ .name = "macos-shader", .src = "src/macos/macos_shader.zig" },
        .windows => .{ .name = "windows-shader", .src = "src/windows/windows_shader.zig" },
        else => @panic("Unsupported OS for the shader example"),
    };

    const impeller_dep = b.dependency("impeller_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const impeller_mod = impeller_dep.module("impeller");

    const glfw_dep = b.lazyDependency("glfw_zig", .{
        .target = target,
        .optimize = optimize,
    }) orelse return;
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
    const glfw_mod = glfw_translate.createModule();

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

    const shader_mod = b.createModule(.{
        .root_source_file = b.path(shader_info.src),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });

    exe_mod.addImport("impeller", impeller_mod);
    exe_mod.addImport("draw", draw_mod);
    exe_mod.addImport("glfw_c", glfw_mod);
    exe_mod.linkLibrary(glfw_lib);

    shader_mod.addImport("impeller", impeller_mod);
    shader_mod.addImport("glfw_c", glfw_mod);
    shader_mod.linkLibrary(glfw_lib);
    shader_mod.addAnonymousImport("draw", .{
        .root_source_file = b.path("src/shaders/draw.zig"),
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

    const shader_exe = b.addExecutable(.{
        .name = shader_info.name,
        .root_module = shader_mod,
        .use_llvm = if (os_tag == .macos) null else true,
        .use_lld = if (os_tag == .macos) null else true,
    });

    exe.each_lib_rpath = false;
    shader_exe.each_lib_rpath = false;

    impeller_pkg.linkRuntime(exe, impeller_dep);
    const runtime_install = impeller_pkg.installRuntime(.{
        .compile_step = exe,
        .dependency = impeller_dep,
    });
    b.getInstallStep().dependOn(runtime_install);

    switch (os_tag) {
        .macos => {
            exe.root_module.addCSourceFile(.{
                .file = b.path("src/macos/macos_glfw_metal.m"),
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

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(&install_exe.step);

    const run_step = b.step("run", "Run the GLFW example");
    run_step.dependOn(&run_cmd.step);

    impeller_pkg.linkRuntime(shader_exe, impeller_dep);

    switch (os_tag) {
        .macos => {
            shader_exe.root_module.addCSourceFile(.{
                .file = b.path("src/macos/macos_glfw_metal.m"),
                .flags = &.{ "-fobjc-arc", "-Wno-deprecated-declarations", "-Wno-unguarded-availability-new" },
                .language = .objective_c,
            });
            shader_exe.root_module.linkFramework("AppKit", .{});
            shader_exe.root_module.linkFramework("Metal", .{});
            shader_exe.root_module.linkFramework("QuartzCore", .{});
            shader_exe.root_module.addRPathSpecial("@executable_path");
        },
        .linux => {
            shader_exe.root_module.linkSystemLibrary("dl", .{});
            shader_exe.root_module.linkSystemLibrary("pthread", .{});
            shader_exe.root_module.linkSystemLibrary("m", .{});
            shader_exe.root_module.addRPathSpecial("$ORIGIN");
        },
        .windows => {},
        else => {},
    }

    const install_shader = b.addInstallArtifact(shader_exe, .{});
    install_shader.step.dependOn(runtime_install);
    b.getInstallStep().dependOn(&install_shader.step);

    const run_shader_cmd = b.addRunArtifact(shader_exe);
    run_shader_cmd.step.dependOn(&install_shader.step);

    const run_shader_step = b.step("run-shader", "Run the fragment shader example");
    run_shader_step.dependOn(&run_shader_cmd.step);
}
