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

    // check fsctl calls
    // ..
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
