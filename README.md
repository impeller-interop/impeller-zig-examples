# impeller-zig-examples

Runnable GLFW examples for [`impeller-zig`](https://github.com/impeller-interop/impeller-zig).

<p align="center">
  <img src="https://github.com/user-attachments/assets/f143b456-1d55-4309-9817-6b53f7ab2ccb" height="300"/>
  <img src="https://github.com/user-attachments/assets/71ce96fe-fbe4-4195-aa36-aeee224b3830" height="300"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/883936cf-6c3b-40b6-a34a-0d6c7388b7cc" width="700"/>
</p>

## Prerequisites

Install Zig master (`0.17.0-dev`) directly, or use [mise](https://github.com/jdx/mise) to install the toolchain pinned by this repository:

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
