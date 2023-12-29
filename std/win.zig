const std = @import("std");
const builtin = @import("builtin");
const native_arch = builtin.cpu.arch;
const kernel32 = @import("win/kernel32.zig");
const LANG = @import("win/lang.zig");
const SUBLANG = @import("win/sublang.zig");

pub const Win32Error = @import("win/win32error.zig").Win32Error;
pub const WINAPI: std.builtin.CallingConvention = if (native_arch == .x86)
    .Stdcall
else
    .C;

pub const BOOL = i32;
pub const PWSTR = [*:0]u16;
pub const PSTR = [*:0]u8;
pub const HANDLE = *anyopaque;
pub const PVOID = *anyopaque;
pub const SIZE_T = usize;
pub const DWORD = u32;
pub const WCHAR = u16;

pub const LPPROC_THREAD_ATTRIBUTE_LIST = *anyopaque;
pub const va_list = *opaque {};
pub const LPVOID = *anyopaque;

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

pub const PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY = extern struct {
    DUMMYUNIONNAME : extern union {
        Flags : DWORD,
        DUMMYSTRUCTNAME : packed struct {
            DisallowWin32kSystemCalls : u1,
            AuditDisallowWin32kSystemCalls : u1,
            ReservedFlags : u30,
        },
    },
};

pub const PROCESS_MITIGATION_POLICY = enum(c_int) {
    ProcessDEPPolicy,
    ProcessASLRPolicy,
    ProcessDynamicCodePolicy,
    ProcessStrictHandleCheckPolicy,
    ProcessSystemCallDisablePolicy,
    ProcessMitigationOptionsMask,
    ProcessExtensionPointDisablePolicy,
    ProcessControlFlowGuardPolicy,
    ProcessSignaturePolicy,
    ProcessFontDisablePolicy,
    ProcessImageLoadPolicy,
    ProcessSystemCallFilterPolicy,
    ProcessPayloadRestrictionPolicy,
    ProcessChildProcessPolicy,
    ProcessSideChannelIsolationPolicy,
    ProcessUserShadowStackPolicy,
    MaxProcessMitigationPolicy
};

pub const GetProcessMitigationPolicyError = error{Unexpected};
pub fn GetProcessMitigationPolicy(
    hProcess: HANDLE,
    MitigationPolicy: PROCESS_MITIGATION_POLICY,
    lpBuffer: PVOID,
    dwLength: SIZE_T,
) GetProcessMitigationPolicyError!void {
    if (kernel32.GetProcessMitigationPolicy(hProcess, MitigationPolicy, lpBuffer, dwLength) == 0) {
        switch (kernel32.GetLastError()) {
            // .FILE_NOT_FOUND => return error.FileNotFound,
            // .PATH_NOT_FOUND => return error.FileNotFound,
            // .MOD_NOT_FOUND => return error.FileNotFound,
            else => |err| return unexpectedError(err),
        }
    }
}

// for unexpectedError
pub const FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;
pub const FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
pub const LANGID = c_ushort;
inline fn MAKELANGID(p: c_ushort, s: c_ushort) LANGID {
    return (s << 10) | p;
}


/// Call this when you made a windows DLL call or something that does SetLastError
/// and you get an unexpected error.
pub fn unexpectedError(err: Win32Error) std.os.UnexpectedError {
    if (std.os.unexpected_error_tracing) {
        // 614 is the length of the longest windows error description
        var buf_wstr: [614]WCHAR = undefined;
        var buf_utf8: [614]u8 = undefined;
        const len = kernel32.FormatMessageW(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            null,
            err,
            MAKELANGID(LANG.NEUTRAL, SUBLANG.DEFAULT),
            &buf_wstr,
            buf_wstr.len,
            null,
        );
        _ = std.unicode.utf16leToUtf8(&buf_utf8, buf_wstr[0..len]) catch unreachable;
        std.debug.print("error.Unexpected: GetLastError({}): {s}\n", .{ @intFromEnum(err), buf_utf8[0..len] });
        std.debug.dumpCurrentStackTrace(@returnAddress());
    }
    return error.Unexpected;
}