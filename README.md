# impeller-zig-examples

Runnable GLFW examples for [`impeller-zig`](https://github.com/impeller-interop/impeller-zig).

<p align="center">
  <img width=30%" alt="macos" src="https://github.com/user-attachments/assets/02905434-18fe-4ce8-a45f-ad320b8e3916" />
  &nbsp;&nbsp;
  <img width=30%" alt="linux" src="https://github.com/user-attachments/assets/57751a2e-e3a6-4531-a346-f8bfb1fdcdc0" />
  &nbsp;&nbsp;
  <img width=30%" alt="windows" src="https://github.com/user-attachments/assets/b25b9830-e3b1-4384-91bf-a139aaea027a" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/883936cf-6c3b-40b6-a34a-0d6c7388b7cc" width="60%" />
</p>

## Prerequisites

Install Zig `0.17.0` directly, or use [mise](https://github.com/jdx/mise) to install the toolchain pinned by this repository:

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

```bash
zig build run
# or:
# only run
```

## Run Shader Example

The shader example uses Vulkan on Linux and Windows, or Metal on macOS:

```bash
zig build run-shader
# or:
# only run-shader
```

## Linux

The Linux example forces the X11 video driver for now.

## Cross-compilation

Cross compile with Zig's standard target option. For example, macOS to Windows:

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

macOS targets require Apple's SDK/frameworks. Linux targets currently need to be
built on a Linux host, because the X11 package builds `makekeys` for the target
and runs it during the build.
