const std = @import("std");
const mystd = @import("mystd");
const winextra = mystd.win_extra;
const posixextra = mystd.posix_extra;
const GetLastError = std.os.windows.kernel32.GetLastError;

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_state.allocator();
    try run(arena);
    arena_state.deinit();
}

fn run(allocator: std.mem.Allocator) !void {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next() orelse @panic("no binary name"); // skip binary name

    const s_handle1 = args.next() orelse @panic("no file1 handle string");
    // const s_handle2 = args.next() orelse @panic("no file2 handle string");
    // const s_handle3 = args.next() orelse @panic("no file3 handle string");
    std.debug.print("{s}\n", .{s_handle1});
    const file_h1 = try posixextra.stringToHandle(s_handle1);
    defer std.posix.close(file_h1);
    // const file_h2 = try posixextra.stringToHandle(s_handle2);
    // defer std.posix.close(file_h2);
    // const file_h3 = try posixextra.stringToHandle(s_handle3);
    // defer std.posix.close(file_h3);

    // child inherited the handle, so inheritance must be enabled
    const is_inheritable1 = try posixextra.isInheritable(file_h1);
    std.debug.assert(is_inheritable1);
    // const is_inheritable2 = try posixextra.isInheritable(file_h2);
    // std.debug.assert(is_inheritable2);
    // const is_inheritable3 = try posixextra.isInheritable(file_h3);
    // std.debug.assert(is_inheritable3);

    try posixextra.disableInheritance(file_h1);
    // try posixextra.disableInheritance(file_h2);
    // try posixextra.disableInheritance(file_h3);
    var file1 = std.fs.File{ .handle = file_h1 };
    const file1_wr = file1.writer();
    // var file2 = std.fs.File{ .handle = file_h2 };
    // const file2_wr = file2.writer();
    // var file3 = std.fs.File{ .handle = file_h3 };
    // const file3_wr = file3.writer();
    try file1_wr.writeAll("file1");
    // try file2_wr.writeAll("file2");
    // try file3_wr.writeAll("file3");
}
