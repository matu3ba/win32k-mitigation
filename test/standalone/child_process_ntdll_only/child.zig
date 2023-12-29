const std = @import("std");
const mystd = @import("mystd");
const win_extra = mystd.win_extra;
const GetLastError = std.os.windows.kernel32.GetLastError;

// 42 is expected by parent; other values result in test failure
var exit_code: u8 = 42;

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_state.allocator();
    try run(arena);
    arena_state.deinit();
    std.process.exit(exit_code);
}

fn run(allocator: std.mem.Allocator) !void {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next() orelse unreachable; // skip binary name

    const SYSCALL_DISABLE_POLICY = win_extra.PROCESS_MITIGATION_POLICY;
    var effectice_policy: win_extra.PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY = undefined;
    const process_handle = std.os.windows.kernel32.GetCurrentProcess();
    win_extra.GetProcessMitigationPolicy(
        process_handle,
        SYSCALL_DISABLE_POLICY.ProcessSystemCallDisablePolicy,
        &effectice_policy,
        @sizeOf(win_extra.PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY),
    ) catch {
        testError("[!] Could not query system call filter policy in child: code '{d}'\n", .{ GetLastError() });
    };

    if (effectice_policy.DUMMYUNIONNAME.DUMMYSTRUCTNAME.DisallowWin32kSystemCalls != 1)
        testError(" [!] Child running with no filtering on Win32k syscalls\n", .{});
    // const L = std.unicode.utf8ToUtf16LeStringLiteral;
    // try std.testing.expectError(error.FileNotFound, std.os.windows.LoadLibraryW(L("USER32.dll")));
    // TestNotLoadLib(TEXT("USER32.dll"));
    // TestNotLoadLib(TEXT("gdi32full.dll"));
    // TestNotLoadLib(TEXT("GDI32.dll"));
    // TestNotLoadLib(TEXT("api-ms-win-gdi-internal-uap-l1-1-0.dll"));

    // if (LoadLibrary(TEXT("gdi32full.dll")) == NULL)
    // {
    //     _tprintf(TEXT(" [.] Checking all gdi32full dependencies:\n"));
    //     TestLoadLib(TEXT("msvcp_win.dll"));
    //     TestLoadLib(TEXT("api-ms-win-crt-string-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-crt-runtime-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-crt-private-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-string-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-localization-l1-2-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-heap-l2-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-rtlsupport-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-libraryloader-l1-2-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-sysinfo-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-1.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-errorhandling-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-processenvironment-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-file-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-handle-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-registry-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-file-l1-2-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-synch-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-heap-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-file-l2-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-threadpool-l1-2-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-debug-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-string-l2-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-security-base-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-1.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-profile-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-interlocked-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-kernel32-legacy-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-heap-obsolete-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-string-obsolete-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-stringansi-l1-1-0.dll"));
    //     TestLoadLib(TEXT("ntdll.dll"));
    //     TestLoadLib(TEXT("win32u.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-1.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-privateprofile-l1-1-0.dll"));
    //     TestLoadLib(TEXT("api-ms-win-core-localization-private-l1-1-0.dll"));
    //     TestNotLoadLib(TEXT("GDI32.dll"));
    //     TestNotLoadLib(TEXT("USER32.dll"));
    //     _tprintf(TEXT(" --- done\n"));
    //
    //     if (LoadLibrary(TEXT("USER32.dll")) == NULL)
    //     {
    //         _tprintf(TEXT(" [.] Checking all user32 dependencies:\n"));
    //         TestLoadLib(TEXT("win32u.dll"));
    //         TestLoadLib(TEXT("ntdll.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-localization-l1-2-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-registry-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-heap-l2-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-libraryloader-l1-2-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-eventing-provider-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-synch-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-string-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-sysinfo-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-security-base-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-handle-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-errorhandling-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-string-l2-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-synch-l1-2-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-processenvironment-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-file-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-1.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-profile-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-heap-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-3.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-privateprofile-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-atoms-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-heap-obsolete-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-string-obsolete-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-localization-obsolete-l1-2-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-stringansi-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-sidebyside-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-kernel32-private-l1-1-0.dll"));
    //         TestLoadLib(TEXT("KERNELBASE.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-kernel32-legacy-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-appinit-l1-1-0.dll"));
    //         TestNotLoadLib(TEXT("GDI32.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-1.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-apiquery-l1-1-0.dll"));
    //         _tprintf(TEXT(" --- done\n"));
    //     }
    //
    //     if (LoadLibrary(TEXT("GDI32.dll")) == NULL)
    //     {
    //         _tprintf(TEXT(" [.] Checking all gdi32 dependencies:\n"));
    //         TestLoadLib(TEXT("ntdll.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-heap-l2-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-libraryloader-l1-2-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-1.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-profile-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-sysinfo-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-errorhandling-l1-1-0.dll"));
    //         TestNotLoadLib(TEXT("api-ms-win-gdi-internal-uap-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-1.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-0.dll"));
    //         TestLoadLib(TEXT("api-ms-win-core-apiquery-l1-1-0.dll"));
    //         _tprintf(TEXT(" --- done\n"));
    //     }
    // }
}

fn testError(comptime fmt: []const u8, args: anytype) void {
    const stderr = std.io.getStdErr().writer();
    stderr.print("CHILD TEST ERROR: ", .{}) catch {};
    stderr.print(fmt, args) catch {};
    if (fmt[fmt.len - 1] != '\n') {
        stderr.writeByte('\n') catch {};
    }
    exit_code = 1;
}