const std = @import("std");
const builtin = @import("builtin");
const native_arch = builtin.cpu.arch;

pub const WINAPI: std.builtin.CallingConvention = if (native_arch == .x86)
    .Stdcall
else
    .C;

pub const BOOL = i32;
pub const PWSTR = [*:0]u16;
pub const PSTR = [*:0]u8;
pub const HANDLE = *anyopaque;

pub const LPPROC_THREAD_ATTRIBUTE_LIST = *anyopaque;

pub const STARTUPINFOEXW = extern struct {
    lpStartupInfo: std.os.windows.STARTUPINFOW,
    lpAttributeList: ?LPPROC_THREAD_ATTRIBUTE_LIST,
};

// zig fmt: off
pub const PROCESS_CREATION_FLAGS = enum(u32) {
    // <- gap here ->
    DEBUG_PROCESS                       = 0x0000_0001,
    DEBUG_ONLY_THIS_PROCESS             = 0x0000_0002,
    CREATE_SUSPENDED                    = 0x0000_0004,
    DETACHED_PROCESS                    = 0x0000_0008,
    CREATE_NEW_CONSOLE                  = 0x0000_0010,
    NORMAL_PRIORITY_CLASS               = 0x0000_0020,
    IDLE_PRIORITY_CLASS                 = 0x0000_0040,
    HIGH_PRIORITY_CLASS                 = 0x0000_0080,
    REALTIME_PRIORITY_CLASS             = 0x0000_0100,
    CREATE_NEW_PROCESS_GROUP            = 0x0000_0200,
    CREATE_UNICODE_ENVIRONMENT          = 0x0000_0400,
    CREATE_SEPARATE_WOW_VDM             = 0x0000_0800,
    CREATE_SHARED_WOW_VDM               = 0x0000_1000,
    CREATE_FORCEDOS                     = 0x0000_2000,
    BELOW_NORMAL_PRIORITY_CLASS         = 0x0000_4000,
    ABOVE_NORMAL_PRIORITY_CLASS         = 0x0000_8000,
    INHERIT_PARENT_AFFINITY             = 0x0001_0000,
    INHERIT_CALLER_PRIORITY             = 0x0002_0000,
    CREATE_PROTECTED_PROCESS            = 0x0004_0000,
    EXTENDED_STARTUPINFO_PRESENT        = 0x0008_0000,
    PROCESS_MODE_BACKGROUND_BEGIN       = 0x0010_0000,
    PROCESS_MODE_BACKGROUND_END         = 0x0020_0000,
    CREATE_SECURE_PROCESS               = 0x0040_0000,
    // <- gap here ->
    CREATE_BREAKAWAY_FROM_JOB           = 0x0100_0000,
    CREATE_PRESERVE_CODE_AUTHZ_LEVEL    = 0x0200_0000,
    CREATE_DEFAULT_ERROR_MODE           = 0x0400_0000,
    CREATE_NO_WINDOW                    = 0x0800_0000,
    PROFILE_USER                        = 0x1000_0000,
    PROFILE_KERNEL                      = 0x2000_0000,
    PROFILE_SERVER                      = 0x4000_0000,
    CREATE_IGNORE_SYSTEM_DEFAULT        = 0x8000_0000,
    _,
};
// zig fmt: on

pub extern "kernel32" fn InitializeProcThreadAttributeList(
    lpAttributeList: ?LPPROC_THREAD_ATTRIBUTE_LIST,
    dwAttributeCount: u32,
    dwFlags: u32,
    lpSize: ?*usize,
) callconv(WINAPI) BOOL;

pub extern "kernel32" fn DeleteProcThreadAttributeList(
    lpAttributeList: ?LPPROC_THREAD_ATTRIBUTE_LIST,
) callconv(WINAPI) void;

pub extern "kernel32" fn UpdateProcThreadAttribute(
    lpAttributeList: ?LPPROC_THREAD_ATTRIBUTE_LIST,
    dwFlags: u32,
    Attribute: usize,
    lpValue: ?*anyopaque,
    cbSize: usize,
    lpPreviousValue: ?*anyopaque,
    lpReturnSize: ?*usize,
) callconv(WINAPI) BOOL;
