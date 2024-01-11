const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "renderer",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    // The SDL package doesn't work for Linux yet, so we rely on system
    // packages for now.
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");

    b.installArtifact(exe);

    const run = b.step("run", "Run the renderer");
    const run_cmd = b.addRunArtifact(exe);
    run.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.linkLibC();
    // The SDL package doesn't work for Linux yet, so we rely on system
    // packages for now.
    unit_tests.linkSystemLibrary("SDL2");
    unit_tests.linkSystemLibrary("SDL2_image");

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
