//! Test explicit list of handles are inherited inspired by
//! https://devblogs.microsoft.com/oldnewthing/20111216-00/?p=8873.
//! "(If you pass an explicit list, then you must pass TRUE for bInherit­Handles.)
//! And as before, for a handle to be inherited, it must be also be marked as inheritable."
const std = @import("std");
const mystd = @import("mystd");
const winextra = mystd.win_extra;
const osextra = mystd.os_extra;
pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer if (gpa_state.deinit() != .ok) {
        @panic("found memory leaks");
    };
    const gpa = gpa_state.allocator();
    try behavior(gpa);
    return if (parent_test_error) error.ParentTestError else {};
}

fn behavior(gpa: std.mem.Allocator) !void {
    const tmpDir = std.testing.tmpDir;
    var tmp = tmpDir(.{});
    defer tmp.cleanup();

    {
        const file1 = try tmp.dir.createFile("testfile1", .{});
        defer file1.close();
        const file2 = try tmp.dir.createFile("testfile2", .{});
        defer file2.close();
        const file3 = try tmp.dir.createFile("testfile3", .{});
        defer file3.close();

        const is_inheritable = try osextra.isInheritable(file1.handle);
        std.debug.assert(is_inheritable == false);
        try osextra.enableInheritance(file1.handle);

        // var handles_to_inherit: [3]winextra.HANDLE = undefined;
        // handles_to_inherit[0] = file1.handle;
        // handles_to_inherit[1] = file2.handle;
        // handles_to_inherit[2] = file3.handle;
        // var handle_to_inherit: winextra.HANDLE = file1.handle;

        var attrs: winextra.LPPROC_THREAD_ATTRIBUTE_LIST = undefined;
        var attrs_len: winextra.SIZE_T = undefined;
        std.testing.expectError(error.InsufficientBuffer, winextra.InitializeProcThreadAttributeList(null, 1, 0, &attrs_len)) catch {
            testError("could not get list size for proc thread attribute list\n", .{});
            return error.Incorrect;
        };
        var attrs_buf: []u8 = undefined;
        attrs_buf = gpa.alloc(u8, attrs_len) catch {
            testError("could not alloc attrs_buf\n", .{});
            return error.Incorrect;
        };
        defer gpa.free(attrs_buf);
        @memset(attrs_buf, 0);
        attrs = @alignCast(@ptrCast(attrs_buf));
        winextra.InitializeProcThreadAttributeList(attrs, 1, 0, &attrs_len) catch {
            testError("could not initialize proc thread attribute list\n", .{});
            return error.Incorrect;
        };
        winextra.UpdateProcThreadAttribute(
            attrs,
            0,
            winextra.PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
            @as(*anyopaque, @ptrCast(@constCast(&file1.handle))),
            @sizeOf(@TypeOf(file1.handle)),
            null,
            null,
        ) catch {
            testError("could not update proc thread attribute list\n", .{});
            return error.Incorrect;
        };

        var it = std.process.argsWithAllocator(gpa) catch {
            testError("could collect args\n", .{});
            return error.Incorrect;
        };
        defer it.deinit();
        _ = it.next() orelse unreachable; // skip binary name
        const child_path = it.next() orelse unreachable;

        var buf_handle1_s: [osextra.handleCharSize]u8 = comptime [_]u8{0} ** osextra.handleCharSize;
        // const s_handle1 = osextra.handleToString(handle_to_inherit, &buf_handle1_s) catch {
        const s_handle1 = osextra.handleToString(file1.handle, &buf_handle1_s) catch {
            testError("could only write {s} instead of {x}\n", .{ buf_handle1_s, file1.handle });
            return error.Incorrect;
        };
        // std.debug.print("chid_path s_handle1 (handle_to_inherit): {s} {s} ({x})\n", .{ child_path, s_handle1, @as(*u8, @ptrCast(handle_to_inherit)) });
        // std.debug.print("chid_path s_handle1 (file1.handle): {s} {s} ({x})\n", .{ child_path, s_handle1, @as(*u8, @ptrCast(file1.handle)) });

        // const s_handle1 = osextra.handleToString(handles_to_inherit[0], &buf_handle1_s) catch unreachable;
        // var buf_handle2_s: [osextra.handleCharSize]u8 = comptime [_]u8{0} ** osextra.handleCharSize;
        // const s_handle2 = osextra.handleToString(handles_to_inherit[1], &buf_handle2_s) catch unreachable;
        // var buf_handle3_s: [osextra.handleCharSize]u8 = comptime [_]u8{0} ** osextra.handleCharSize;
        // const s_handle3 = osextra.handleToString(handles_to_inherit[2], &buf_handle3_s) catch unreachable;

        // var child = mystd.ChildProcess.init(&.{ child_path, s_handle1, s_handle2, s_handle3 }, gpa);
        var child = mystd.ChildProcess.init(&.{ child_path, s_handle1 }, gpa);
        child.stdin_behavior = .Close;
        child.stdout_behavior = .Close;
        child.stderr_behavior = .Inherit;
        child.proc_thread_attr_list = attrs;

        child.spawn() catch {
            testError("could not spawn child process\n", .{});
            return error.Incorrect;
        };

        const wait_res = child.wait() catch {
            testError("could not wait for child process\n", .{});
            return error.Incorrect;
        };

        switch (wait_res) {
            .Exited => |code| {
                const child_ok_code = 0;
                if (code != child_ok_code) {
                    testError("child exit code: {d}; want {d}", .{ code, child_ok_code });
                    return error.Incorrect;
                }
            },
            else => |term| {
                testError("abnormal child exit: {}", .{term});
                return error.Incorrect;
            },
        }
    }

    {
        const file1 = try tmp.dir.openFile("testfile1", .{});
        defer file1.close();
        var res_buf: [100]u8 = undefined;
        const file1_len = try file1.readAll(&res_buf);
        std.testing.expectEqualSlices(u8, "file1", res_buf[0..file1_len]) catch {
            return error.Incorrect;
        };

        // const file2_len = try file1.readAll(&res_buf);
        // std.testing.expectEqualSlices(u8, "file2", res_buf[0..file2_len]) catch {
        //     return error.Incorrect;
        // };
        // const file3_len = try file1.readAll(&res_buf);
        // std.testing.expectEqualSlices(u8, "file3", res_buf[0..file3_len]) catch {
        //     return error.Incorrect;
        // };
    }
}

var parent_test_error = false;

fn testError(comptime fmt: []const u8, args: anytype) void {
    const stderr = std.io.getStdErr().writer();
    stderr.print("PARENT TEST ERROR: ", .{}) catch {};
    stderr.print(fmt, args) catch {};
    if (fmt[fmt.len - 1] != '\n') {
        stderr.writeByte('\n') catch {};
    }
    parent_test_error = true;
}
