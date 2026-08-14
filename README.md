# impeller-zig-examples

Runnable SDL3 and GLFW examples for [`impeller-zig`](https://github.com/impeller-interop/impeller-zig).

<p align="center">
  <img src="https://github.com/user-attachments/assets/f143b456-1d55-4309-9817-6b53f7ab2ccb" height="300"/>
  <img src="https://github.com/user-attachments/assets/71ce96fe-fbe4-4195-aa36-aeee224b3830" height="300"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/91145633-42b5-429e-9b43-99e7b27af426" width="700"/>
</p>

## Prerequisites

Install [Zig](https://ziglang.org/download/) `0.16.0` directly, or use [mise](https://github.com/jdx/mise) to install the toolchain pinned by this repository:

```bash
mise install
```

[Only](https://github.com/KercyDing/only) is optional and provides shorter versions of the commands below.

## Build

Build both the API showcase and the shader example:

```bash
zig build
# or:
# only build
```

## Run Examples

SDL3 is the default window backend:

```bash
zig build run
# or:
# only run
```

Run the API showcase with GLFW instead:

```bash
zig build run -Dbackend=glfw
# or:
# only run glfw
```

## Run Shader Example

The shader example always uses SDL3, with Vulkan on Linux and Windows or Metal on macOS:

```bash
zig build run-shader
# or:
# only run-shader
```

## Linux

The SDL3 Linux example forces the X11 video driver for now.

## Cross-compilation

Cross compile with Zig's standard target option. For example, Linux to Windows:

```bash
zig build -Dtarget=x86_64-windows-gnu
```

Supported Impeller SDK targets:

| Platform | `-Dtarget` |
| --- | --- |
| Linux x64 | `x86_64-linux-gnu` |
| Linux arm64 | `aarch64-linux-gnu` |
| macOS x64 | `x86_64-macos` |
| macOS arm64 | `aarch64-macos` |
| Windows x64 | `x86_64-windows-gnu` |
| Windows arm64 | `aarch64-windows-gnu` |

Cross-compilation depends on the window backend.

macOS targets require Apple's SDK/frameworks. GLFW currently cannot target Linux arm64 from a Linux x64 host.
