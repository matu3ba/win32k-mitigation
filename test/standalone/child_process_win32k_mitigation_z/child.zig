const std = @import("std");
const mystd = @import("mystd");
const winextra = mystd.win_extra;
const GetLastError = std.os.windows.kernel32.GetLastError;

var exit_code: u8 = 0;

pub fn main() !void {
    try run();
    std.process.exit(exit_code);
}

fn run() !void {
    const SYSCALL_DISABLE_POLICY = winextra.PROCESS_MITIGATION_POLICY;
    var effectice_policy: winextra.PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY = undefined;
    const process_handle = std.os.windows.kernel32.GetCurrentProcess();
    winextra.GetProcessMitigationPolicy(
        process_handle,
        SYSCALL_DISABLE_POLICY.ProcessSystemCallDisablePolicy,
        &effectice_policy,
        @sizeOf(@TypeOf(effectice_policy)),
    ) catch {
        testError("[!] Could not query system call filter policy in child: code '{d}'\n", .{ GetLastError() });
        return;
    };

    if (effectice_policy.DUMMYUNIONNAME.DUMMYSTRUCTNAME.DisallowWin32kSystemCalls != 1) {
        testError(" [!] Child running with no filtering on Win32k syscalls\n", .{});
        return;
    }
    const L = std.unicode.utf8ToUtf16LeStringLiteral;

    const ntdll_mod = try winextra.LoadLibraryW(L("ntdll.dll"));
    winextra.FreeLibrary(ntdll_mod);
    try std.testing.expectError(error.InitFailed, winextra.LoadLibraryW(L("USER32.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("USER32.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("USER32.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("USER32.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("USER32.dll")));

    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("gdi32full.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("GDI32.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("api-ms-win-gdi-internal-uap-l1-1-0.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("USER32.dll")));

    // checking gdi32full.dll dependencies
    _ = try winextra.LoadLibraryW(L("msvcp_win.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-crt-string-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-crt-runtime-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-crt-private-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-string-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-localization-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-l2-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-rtlsupport-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-libraryloader-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-sysinfo-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-memory-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-errorhandling-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processenvironment-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-file-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-handle-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-registry-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-file-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-synch-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-file-l2-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-memory-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-threadpool-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processthreads-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-debug-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-string-l2-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-security-base-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processthreads-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-profile-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-interlocked-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-kernel32-legacy-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-obsolete-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-string-obsolete-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-stringansi-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("ntdll.dll"));
    _ = try winextra.LoadLibraryW(L("win32u.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-delayload-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-delayload-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-privateprofile-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-localization-private-l1-1-0.dll"));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("GDI32.dll")));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("USER32.dll")));

    // checking user32 dependencies
    _ = try winextra.LoadLibraryW(L("win32u.dll"));
    _ = try winextra.LoadLibraryW(L("ntdll.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-localization-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-registry-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-l2-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-libraryloader-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-eventing-provider-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processthreads-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-synch-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-string-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-sysinfo-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-security-base-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-handle-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-errorhandling-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-string-l2-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-synch-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processenvironment-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-file-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processthreads-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-memory-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-profile-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-memory-l1-1-3.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-privateprofile-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-atoms-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-obsolete-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-string-obsolete-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-localization-obsolete-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-stringansi-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-sidebyside-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-kernel32-private-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("KERNELBASE.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-kernel32-legacy-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-appinit-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-delayload-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-delayload-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-apiquery-l1-1-0.dll"));

    // checking gdi32 dependencies
    _ = try winextra.LoadLibraryW(L("ntdll.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-heap-l2-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-libraryloader-l1-2-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processthreads-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-processthreads-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-profile-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-sysinfo-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-errorhandling-l1-1-0.dll"));
    try std.testing.expectError(error.OutOfVirtualMemory, winextra.LoadLibraryW(L("api-ms-win-gdi-internal-uap-l1-1-0.dll")));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-delayload-l1-1-1.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-delayload-l1-1-0.dll"));
    _ = try winextra.LoadLibraryW(L("api-ms-win-core-apiquery-l1-1-0.dll"));
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