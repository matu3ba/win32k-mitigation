const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const lib = b.addStaticLibrary(.{
    //     .name = "win32k-mitigation",
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "win32k-mitigation",
        .root_source_file = .{ .path = "src/main.c" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.addCSourceFile(.{
        .file = .{ .path = "src/mem.c" },
        .flags =  &.{},
    });
    exe.addIncludePath(std.build.LazyPath.relative("include"));
    exe.linkLibCpp();

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const childproc_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/child_process.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_childproc_unit_tests = b.addRunArtifact(childproc_unit_tests);

    const dep = b.anonymousDependency("test/standalone/child_process", @import("test/standalone/child_process/build.zig"), .{},);
    const dep_step = dep.builder.default_step;
    assert(mem.startsWith(u8, dep.builder.dep_prefix, "test."));
    const dep_prefix_adjusted = dep.builder.dep_prefix["test.".len..];
    dep_step.name = b.fmt("{s}{s}", .{ dep_prefix_adjusted, dep_step.name });

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_childproc_unit_tests.step);
    test_step.dependOn(dep_step);
    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    // test_step.dependOn(&run_exe_unit_tests.step);
}