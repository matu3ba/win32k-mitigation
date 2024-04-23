//! Test PROCESS_CREATION_MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE
//! prevents user32 libraries to be loadable.
const std = @import("std");
const mystd = @import("mystd");
const winextra = mystd.win_extra;
pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer if (gpa_state.deinit() != .ok) {
        @panic("found memory leaks");
    };
    const gpa = gpa_state.allocator();
    behavior(gpa) catch {
        parent_test_error = true;
    };
    return if (parent_test_error) error.ParentTestError else {};
}

const BehaviorError = error{Incorrect};

fn behavior(gpa: std.mem.Allocator) BehaviorError!void {
    const mitigation_policy: winextra.DWORD = winextra.PROCESS_CREATION_MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE.ALWAYS_ON;
    var attrs: winextra.LPPROC_THREAD_ATTRIBUTE_LIST = undefined;
    var attrs_len: winextra.SIZE_T = undefined;
    std.testing.expectError(error.InsufficientBuffer, winextra.InitializeProcThreadAttributeList(null, 1, 0, &attrs_len)) catch {
        testError("could not get list size for proc thread attribute list\n", .{});
        return error.Incorrect;
    };
    var attrs_buf: []u8 = undefined;
    attrs_buf = gpa.alloc(u8, attrs_len) catch {
        testError("could not alloc\n", .{});
        return error.Incorrect;
    };
    defer gpa.free(attrs_buf);
    @memset(attrs_buf, 0);
    attrs = @alignCast(@ptrCast(attrs_buf.ptr));
    winextra.InitializeProcThreadAttributeList(attrs, 1, 0, &attrs_len) catch {
        testError("could not initialize proc thread attribute list\n", .{});
        return error.Incorrect;
    };

    winextra.UpdateProcThreadAttribute(
        attrs,
        0,
        winextra.PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY,
        @constCast(&mitigation_policy),
        @sizeOf(@TypeOf(mitigation_policy)),
        null,
        null,
    ) catch {
        testError("could not update proc thread attribute list\n", .{});
        return error.Incorrect;
    };

    var it = std.process.argsWithAllocator(gpa) catch {
        testError("could not collect args\n", .{});
        return error.Incorrect;
    };
    defer it.deinit();
    _ = it.next() orelse unreachable; // skip binary name
    const child_path = it.next() orelse unreachable;

    var child = mystd.ChildProcess.init(&.{child_path}, gpa);
    child.stdin_behavior = .Close;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    child.proc_thread_attr_list = attrs;

    child.spawn() catch {
        testError("could not spawn child\n", .{});
        return error.Incorrect;
    };

    const wait_res = child.wait() catch {
        testError("could not wait for child\n", .{});
        return error.Incorrect;
    };

    switch (wait_res) {
        .Exited => |code| {
            const child_ok_code = 0; // set by child if no test errors
            if (code != 0) {
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
