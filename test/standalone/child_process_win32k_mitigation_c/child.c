#include <Windows.h>
#include <tchar.h>
#include <stdio.h>
#include <stdbool.h>

static bool TestLoadLib(PCTSTR swzName)
{
    if (LoadLibrary(swzName) == NULL)
    {
        _tprintf(TEXT(" [!] Unable to load %s: code %lu\n"), swzName, GetLastError());
        return false;
    }
    return true;
}

static bool TestNotLoadLib(PCTSTR swzName, WORD expectedErr)
{
    if (LoadLibrary(swzName) != NULL)
    {
        _tprintf(TEXT(" [!] Was able to load %s\n"), swzName);
        return false;
    }
    WORD lastErr = GetLastError();
    if (lastErr != expectedErr) {
        _tprintf(TEXT(" [!] Got %d, expected %d\n"), lastErr, expectedErr);
        return false;
    }
    return true;
}

int _tmain(int argc, PCTSTR argv[])
{
    printf("[.] Child process created\n");
    PROCESS_MITIGATION_SYSTEM_CALL_DISABLE_POLICY effectivePolicy = { 0 };
    bool has_err = false;
    if (!GetProcessMitigationPolicy(GetCurrentProcess(), ProcessSystemCallDisablePolicy, &effectivePolicy, sizeof(effectivePolicy)))
    {
        _tprintf(TEXT(" [!] Could not query system call filter policy in child: code %lu\n"), GetLastError());
        has_err = true;
    }
    else if (!effectivePolicy.DisallowWin32kSystemCalls)
    {
        _tprintf(TEXT(" [!] Child running with no filtering on Win32k syscalls\n"));
        has_err = true;
    }
    else
    {
        _tprintf(TEXT(" [+] Child running with filtered Win32k syscalls\n"));
    }

    if (TestNotLoadLib(TEXT("USER32.dll"), ERROR_DLL_INIT_FAILED) == false) has_err = true;
    // yes, this makes no sense whatsoever
    if (TestNotLoadLib(TEXT("gdi32full.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;
    if (TestNotLoadLib(TEXT("GDI32.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;
    if (TestNotLoadLib(TEXT("api-ms-win-gdi-internal-uap-l1-1-0.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;

    if (has_err == true) goto cleanup;

    _tprintf(TEXT(" [.] Checking all gdi32full dependencies:\n"));
    if (TestLoadLib(TEXT("msvcp_win.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-crt-string-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-crt-runtime-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-crt-private-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-string-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-localization-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-l2-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-rtlsupport-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-libraryloader-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-sysinfo-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-errorhandling-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processenvironment-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-file-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-handle-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-registry-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-file-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-synch-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-file-l2-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-threadpool-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-debug-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-string-l2-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-security-base-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-profile-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-interlocked-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-kernel32-legacy-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-obsolete-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-string-obsolete-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-stringansi-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("ntdll.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("win32u.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-privateprofile-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-localization-private-l1-1-0.dll")) == false) has_err = true;
    if (TestNotLoadLib(TEXT("GDI32.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;
    if (TestNotLoadLib(TEXT("USER32.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;
    _tprintf(TEXT(" --- done\n"));

    if (has_err == true) goto cleanup;

    _tprintf(TEXT(" [.] Checking all user32 dependencies:\n"));
    if (TestLoadLib(TEXT("win32u.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("ntdll.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-localization-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-registry-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-l2-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-libraryloader-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-eventing-provider-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-synch-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-string-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-sysinfo-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-security-base-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-handle-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-errorhandling-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-string-l2-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-synch-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processenvironment-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-file-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-profile-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-memory-l1-1-3.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-privateprofile-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-atoms-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-obsolete-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-string-obsolete-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-localization-obsolete-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-stringansi-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-sidebyside-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-kernel32-private-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("KERNELBASE.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-kernel32-legacy-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-appinit-l1-1-0.dll")) == false) has_err = true;
    if (TestNotLoadLib(TEXT("GDI32.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-apiquery-l1-1-0.dll")) == false) has_err = true;
    _tprintf(TEXT(" --- done\n"));

    if (has_err == true) goto cleanup;

    _tprintf(TEXT(" [.] Checking all gdi32 dependencies..\n"));
    if (TestLoadLib(TEXT("ntdll.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-heap-l2-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-libraryloader-l1-2-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-processthreads-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-profile-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-sysinfo-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-errorhandling-l1-1-0.dll")) == false) has_err = true;
    if (TestNotLoadLib(TEXT("api-ms-win-gdi-internal-uap-l1-1-0.dll"), ERROR_NOT_ENOUGH_MEMORY) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-1.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-delayload-l1-1-0.dll")) == false) has_err = true;
    if (TestLoadLib(TEXT("api-ms-win-core-apiquery-l1-1-0.dll")) == false) has_err = true;
    _tprintf(TEXT(" --- done\n"));

cleanup:
    if (has_err) return 666;
    else return 0;
}
