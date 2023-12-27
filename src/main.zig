const std = @import("std");
const win = std.os.windows;
const mem = std.mem;

pub fn main() !void {
    // TODO
    // var selfpath_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    // * PPROC_THREAD_ATTRIBUTE_LIST pAttr = NULL;
    // * DWORD dwMitigationPolicy = PROCESS_CREATION_MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON;
    // * STARTUPINFOEX startInfo = { 0 };
    // * PROCESS_INFORMATION procInfo = { 0 };
    // * PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY effectivePolicy = { 0 };

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Run `zig build test` to run the tests.\n", .{});
    try bw.flush(); // don't forget to flush!

    // var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(!general_purpose_allocator.deinit());
    // const gpa = general_purpose_allocator.allocator();

    var cmdline_buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&cmdline_buffer);
    const args = std.process.argsAlloc(fba.allocator()) catch
        @panic("unable to parse command line args");
    if (args.len >= 1 and std.mem.eql(u8, "self-run", args[0])) {
        // is child process
        try stdout.writeAll(" [.] Child process started successfully\n");
    }

    // if (!GetProcessMitigationPolicy(GetCurrentProcess(), ProcessSystemCallDisablePolicy, &effectivePolicy, sizeof(effectivePolicy)))
    // {
    //     _tprintf(TEXT(" [!] Could not query system call filter policy in child: code %lu\n"), GetLastError());
    // }
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }