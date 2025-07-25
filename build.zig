const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spoon_mod = b.addModule("spoon", .{
        .root_source_file = b.path("import.zig"),
        .target = target,
        .optimize = optimize,
    });

    // spoon_mod.addImport("spoon", spoon_mod);

    const tests = b.addTest(
        .{
            .root_source_file = b.path("test_main.zig"),
            .target = target,
            .optimize = optimize,
        },
    );
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    {
        const exe = b.addExecutable(
            .{
                .name = "menu",
                .root_source_file = b.path("example/menu.zig"),
                .target = target,
                .optimize = optimize,
            },
        );
        exe.root_module.addImport("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "menu-libc",
                .root_source_file = b.path("example/menu.zig"),
                .target = target,
                .optimize = optimize,
            },
        );
        exe.root_module.addImport("spoon", spoon_mod);
        exe.linkLibC();
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "input-demo",
                .root_source_file = b.path("example/input-demo.zig"),
                .target = target,
                .optimize = optimize,
            },
        );
        exe.root_module.addImport("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "colours",
                .root_source_file = b.path("example/colours.zig"),
                .target = target,
                .optimize = optimize,
            },
        );
        exe.root_module.addImport("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "table-256-colours",
                .root_source_file = b.path("example/table-256-colours.zig"),
                .target = target,
                .optimize = optimize,
            },
        );
        exe.root_module.addImport("spoon", spoon_mod);
        b.installArtifact(exe);
    }
}
