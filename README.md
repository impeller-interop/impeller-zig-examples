# impeller-zig-examples

Runnable SDL3 and GLFW examples for [`impeller-zig`](https://github.com/impeller-interop/impeller-zig).

## Dependencies

This package depends on:

- `impeller_zig`
- `sdl3`
- `glfw_zig`

## Run

Run on the current machine:

```bash
zig build run
```

SDL3 is the default backend.

Use GLFW instead:

```bash
zig build run -Dbackend=glfw
```

The SDL3 Linux example forces the X11 video driver for now.

Cross compile with Zig's standard target option. For example, Linux to Windows:

```bash
zig build -Dtarget=x86_64-windows-gnu
```

Available Impeller SDK targets:

| Platform | `-Dtarget` |
| --- | --- |
| Linux x64 | `x86_64-linux-gnu` |
| Linux arm64 | `aarch64-linux-gnu` |
| macOS x64 | `x86_64-macos` |
| macOS arm64 | `aarch64-macos` |
| Windows x64 | `x86_64-windows-gnu` |
| Windows arm64 | `aarch64-windows-gnu` |

These examples also build SDL3/GLFW and platform windowing code, so not every SDK target can be cross compiled from every host. macOS targets need Apple's SDK/frameworks, and Linux arm64 currently needs extra windowing cross-build support.

## Resource ownership

- Every Impeller handle returned by an `init` or `build` call is released exactly once with `deinit`.
- Paints with filters or color sources use independent lexical scopes; handles are never overwritten while a deferred release is pending.
- `Scene` retains the registered font bytes for its full lifetime because the current binding registers a borrowed mapping without exposing Impeller's release callback.
- `Scene.deinit` releases the display list before its texture and retained font storage.

## Known issue

`zig build run` may print Vulkan swapchain validation errors. This comes from the current Impeller SDK, not these examples, and may be fixed by a future SDK update.
