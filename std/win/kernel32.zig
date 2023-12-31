// const mystd = @import("../std.zig");
// const win = mystd.win;
const win = @import("../win.zig");

pub extern "kernel32" fn FormatMessageW(dwFlags: win.DWORD, lpSource: ?win.LPVOID, dwMessageId: win.Win32Error, dwLanguageId: win.DWORD, lpBuffer: [*]u16, nSize: win.DWORD, Arguments: ?*win.va_list) callconv(win.WINAPI) win.DWORD;
pub extern "kernel32" fn GetLastError() callconv(win.WINAPI) win.Win32Error;

pub extern "kernel32" fn GetProcessMitigationPolicy(
    hProcess: win.HANDLE,
    MitigationPolicy: win.PROCESS_MITIGATION_POLICY,
    lpBuffer: win.PVOID,
    dwLength: win.SIZE_T,
) callconv(win.WINAPI) win.BOOL;

pub extern "kernel32" fn InitializeProcThreadAttributeList(
    lpAttributeList: ?win.LPPROC_THREAD_ATTRIBUTE_LIST,
    dwAttributeCount: u32,
    dwFlags: u32,
    lpSize: ?*usize,
) callconv(win.WINAPI) win.BOOL;

pub extern "kernel32" fn DeleteProcThreadAttributeList(
    lpAttributeList: ?win.LPPROC_THREAD_ATTRIBUTE_LIST,
) callconv(win.WINAPI) void;

pub extern "kernel32" fn UpdateProcThreadAttribute(
    lpAttributeList: ?win.LPPROC_THREAD_ATTRIBUTE_LIST,
    dwFlags: u32,
    Attribute: usize,
    lpValue: ?*anyopaque,
    cbSize: usize,
    lpPreviousValue: ?*anyopaque,
    lpReturnSize: ?*usize,
) callconv(win.WINAPI) win.BOOL;

pub extern "kernel32" fn GetHandleInformation(hObject: win.HANDLE, dwFlags: *win.DWORD) callconv(win.WINAPI) win.BOOL;

// ====redundant error fix
pub extern "kernel32" fn LoadLibraryW(lpLibFileName: [*:0]const u16) callconv(win.WINAPI) ?win.HMODULE;
pub extern "kernel32" fn FreeLibrary(hModule: win.HMODULE) callconv(win.WINAPI) win.BOOL;