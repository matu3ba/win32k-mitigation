const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const mem = std.mem;

// TODO detect host platform == windows
// TODO test both native and gnu => function with 2 return types
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

    // const exe_zig = b.addExecutable(.{
    //     .name = "win32k_mitigation_zig",
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // b.installArtifact(exe_zig);
    //
    // const run_cmd_exe_zig = b.addRunArtifact(exe_zig);
    //
    // if (b.args) |args| {
    //     run_cmd_exe_zig.addArgs(args);
    // }
    //
    // const run_step_zig = b.step("runz", "Run the zig app");
    // run_step_zig.dependOn(&run_cmd_exe_zig.step);

    const childproc_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "std/child_process.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_childproc_unit_tests = b.addRunArtifact(childproc_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_childproc_unit_tests.step);
    const mystd = b.createModule(.{ .root_source_file = .{ .path = "std.zig" } });

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
        main.root_module.addImport("mystd", mystd);
        const run_childproc_module_test = b.addRunArtifact(main);
        run_childproc_module_test.addArtifactArg(child);
        run_childproc_module_test.step.dependOn(b.getInstallStep());
        run_childproc_module_test.expectExitCode(0);

        test_step.dependOn(&run_childproc_module_test.step);
    }

    if (builtin.os.tag != .wasi) {
        const main_c = b.addExecutable(.{
            .name = "main_win32k_mitigation_c",
            .target = target,
            .optimize = optimize,
        });

        main_c.addCSourceFile(.{
            .file = .{ .path = "test/standalone/child_process_win32k_mitigation_c/main.c" },
            .flags = &.{},
        });
        main_c.addCSourceFile(.{
            .file = .{ .path = "test/standalone/child_process_win32k_mitigation_c/mem.c" },
            .flags = &.{},
        });
        main_c.linkLibC();
        b.installArtifact(main_c);

        const child_c = b.addExecutable(.{
            .name = "child_win32k_mitigation_c",
            .target = target,
            .optimize = optimize,
        });
        child_c.addCSourceFile(.{
            .file = .{ .path = "test/standalone/child_process_win32k_mitigation_c/child.c" },
            .flags = &.{},
        });
        child_c.addCSourceFile(.{
            .file = .{ .path = "test/standalone/child_process_win32k_mitigation_c/mem.c" },
            .flags = &.{},
        });
        child_c.linkLibC();
        b.installArtifact(child_c);

        const run_win32k_mitigation_c_test = b.addRunArtifact(main_c);
        run_win32k_mitigation_c_test.addArtifactArg(child_c);
        // https://github.com/ziglang/zig/issues/18459
        // bug 20-30% chance to trigger unrecoverable from renaming file during compilation:
        // 1. change following line to '..expectExitCode(1);'
        // 2. zig build runcmiti
        // 3. during build, change back to '..expectExitCode(0);'
        // 4. Observe potentially
        // $ zig build runcmiti
        // runcmiti
        // └─ run main_win32k_mitigation_c failure
        // error: the following command exited with code 0 (expected exited with code 1):
        // C:\Users\user\dev\zi\cpywin32k-mitigation\zig-out\bin\main_win32k_mitigation_c.exe C:\Users\user\dev\zi\cpywin32k-mitigation\zig-out\bin\child_win32k_mitigation_c.exe
        // Build Summary: 9/11 steps succeeded; 1 failed (disable with --summary none)
        // runcmiti transitive failure
        // └─ run main_win32k_mitigation_c failure
        // error: the following build command failed with exit code 1:
        // C:\Users\user\dev\zi\cpywin32k-mitigation\zig-cache\o\42b8f2908c24689b75204e05f9fde811\build.exe C:\Users\user\bin\zig.exe C:\Users\user\dev\zi\cpywin32k-mitigation C:\Users\user\dev\zi\cpywin32k-mitigation\zig-cache C:\Users\user\AppData\Local\zig --seed 0x7506bb65 runcmiti
        // 5. Observe deterministically
        // $ zig build runcmiti
        // error: failed to rename compilation results ('C:\Users\user\dev\zi\win32k-mitigation\zig-cache\tmp\15adb3c4a03dd078') into local cache ('C:\Users\user\dev\zi\win32k-mitigation\zig-cache\o\0df9a39edc521d2b17c1fd98d3777908'): AccessDenied
        run_win32k_mitigation_c_test.step.dependOn(b.getInstallStep());
        run_win32k_mitigation_c_test.expectExitCode(0);

        // TODO
        const run_step_cmiti = b.step("runcmiti", "Run C win32k mitigation child process test.");
        run_step_cmiti.dependOn(&run_win32k_mitigation_c_test.step);
        test_step.dependOn(&run_win32k_mitigation_c_test.step);
    }

    // moved out build.zig from child_process_ntdll_only
    // TODO https://github.com/matu3ba/win32k-mitigation/issues/1
    if (builtin.os.tag != .wasi) {
        const child = b.addExecutable(.{
            .name = "child_win32k_mitigation_z",
            .root_source_file = .{ .path = "test/standalone/child_process_win32k_mitigation_z/child.zig" },
            .optimize = optimize,
            .target = target,
        });
        child.root_module.addImport("mystd", mystd);
        b.installArtifact(child);

        const main = b.addExecutable(.{
            .name = "main_win32k_mitigation_z",
            .root_source_file = .{ .path = "test/standalone/child_process_win32k_mitigation_z/main.zig" },
            .optimize = optimize,
            .target = target,
        });
        main.root_module.addImport("mystd", mystd);
        b.installArtifact(main);
        const run_step_zmiti = b.addRunArtifact(main);
        run_step_zmiti.addArtifactArg(child);
        run_step_zmiti.step.dependOn(b.getInstallStep());
        run_step_zmiti.expectExitCode(0);

        // TODO
        test_step.dependOn(&run_step_zmiti.step);
        const step_zmiti = b.step("runzmiti", "Run Zig win32k mitigation child process test.");
        step_zmiti.dependOn(&run_step_zmiti.step);
    }

    // moved out build.zig from child_process_explicit_handles
    if (builtin.os.tag != .wasi) {
        const main = b.addExecutable(.{
            .name = "main_explicit_handles_cpp",
            .optimize = optimize,
            .target = target,
        });
        main.addCSourceFile(.{ .file = .{ .path = "test/standalone/child_process_explicit_handles_c/main.cpp" }, .flags = &[0][]const u8{} });
        main.linkLibCpp();
        b.installArtifact(main);

        const runcpp_exh = b.addRunArtifact(main);
        // runcpp_exh.step.dependOn(b.getInstallStep());
        runcpp_exh.expectExitCode(0);

        // TODO
        test_step.dependOn(&runcpp_exh.step);
        const cpp_exh_step = b.step("runcppexh", "Run C++ explicit handle inherit child process test.");
        cpp_exh_step.dependOn(&runcpp_exh.step);
    }

    if (builtin.os.tag != .wasi) {
        const child = b.addExecutable(.{
            .name = "child_explicit_handles_z",
            .root_source_file = .{ .path = "test/standalone/child_process_explicit_handles/child.zig" },
            .optimize = optimize,
            .target = target,
        });
        child.root_module.addImport("mystd", mystd);
        b.installArtifact(child);

        const main = b.addExecutable(.{
            .name = "main_explicit_handles_z",
            .root_source_file = .{ .path = "test/standalone/child_process_explicit_handles/main.zig" },
            .optimize = optimize,
            .target = target,
        });
        main.root_module.addImport("mystd", mystd);
        b.installArtifact(main);
        const run_explicit_handle_test = b.addRunArtifact(main);
        run_explicit_handle_test.addArtifactArg(child);
        // run_explicit_handle_test.step.dependOn(b.getInstallStep());
        run_explicit_handle_test.expectExitCode(0);

        // TODO
        test_step.dependOn(&run_explicit_handle_test.step);
        const runz_exh_step = b.step("runzexh", "Run Zig explicit handle inherit child process test.");
        runz_exh_step.dependOn(&run_explicit_handle_test.step);
    }

    // if (builtin.os.tag != .wasi) {
    //     const child = b.addExecutable(.{
    //         .name = "child_no_fsctl_z",
    //         .root_source_file = .{ .path = "test/standalone/child_process_no_fsctl_z/child.zig" },
    //         .optimize = optimize,
    //         .target = target,
    //     });
    //     child.root_module.addImport("mystd", mystd);
    //     b.installArtifact(child);
    //
    //     const main = b.addExecutable(.{
    //         .name = "main_no_fsctl_z",
    //         .root_source_file = .{ .path = "test/standalone/child_process_no_fsctl_z/main.zig" },
    //         .optimize = optimize,
    //         .target = target,
    //     });
    //     main.root_module.addImport("mystd", mystd);
    //     b.installArtifact(main);
    //     const run_explicit_handle_test = b.addRunArtifact(main);
    //     run_explicit_handle_test.addArtifactArg(child);
    //     // run_explicit_handle_test.step.dependOn(b.getInstallStep());
    //     run_explicit_handle_test.expectExitCode(0);
    //
    //     // TODO
    //     test_step.dependOn(&run_explicit_handle_test.step);
    //     const runz_exh_step = b.step("runznofsctl", "Run no syscall fsctl Zig child process test");
    //     runz_exh_step.dependOn(&run_explicit_handle_test.step);
    // }
}
