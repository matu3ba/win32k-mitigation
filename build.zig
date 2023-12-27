const std = @import("std");
const builtin = @import("builtin");
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

    const exe_c = b.addExecutable(.{
        .name = "win32k-mitigation-c",
        .root_source_file = .{ .path = "src/main.c" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe_c.addCSourceFile(.{
        .file = .{ .path = "src/mem.c" },
        .flags =  &.{},
    });
    exe_c.addIncludePath(std.build.LazyPath.relative("include"));
    b.installArtifact(exe_c);

    const exe_zig = b.addExecutable(.{
        .name = "win32k-mitigation-zig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe_zig);

    const run_cmd_exe_c = b.addRunArtifact(exe_c);
    run_cmd_exe_c.step.dependOn(b.getInstallStep());
    const run_cmd_exe_zig = b.addRunArtifact(exe_zig);
    run_cmd_exe_zig.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd_exe_c.addArgs(args);
        run_cmd_exe_zig.addArgs(args);
    }

    const run_step_c = b.step("runc", "Run the c app");
    run_step_c.dependOn(&run_cmd_exe_c.step);
    const run_step_zig = b.step("runz", "Run the zig app");
    run_step_zig.dependOn(&run_cmd_exe_zig.step);

    const childproc_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "std/child_process.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_childproc_unit_tests = b.addRunArtifact(childproc_unit_tests);

    const test_step = b.step("test", "Run unit tests");

    // moved out build.zig from child_process
    if (builtin.os.tag != .wasi) {
        const child = b.addExecutable(.{
            .name = "child",
            .root_source_file = .{ .path = "test/standalone/child_process/child.zig" },
            .optimize = optimize,
            .target = target,
        });

        const main = b.addExecutable(.{
            .name = "main",
            .root_source_file = .{ .path = "test/standalone/child_process/main.zig" },
            .optimize = optimize,
            .target = target,
        });
        const mystd = b.createModule(.{ .source_file = .{ .path = "std.zig" } });
        main.addModule("mystd", mystd);
        const run_childproc_module_test = b.addRunArtifact(main);
        run_childproc_module_test.addArtifactArg(child);
        run_childproc_module_test.expectExitCode(0);

        test_step.dependOn(&run_childproc_module_test.step);
    }

    test_step.dependOn(&run_childproc_unit_tests.step);
    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    // test_step.dependOn(&run_exe_unit_tests.step);
}