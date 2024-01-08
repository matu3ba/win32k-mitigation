#include <Windows.h>
#include <tchar.h>
#include <stdio.h>
#include "mem.h"

int _tmain(int argc, PCTSTR argv[])
{
    printf("[.] Main process created\n");
    int res = 0;
    PPROC_THREAD_ATTRIBUTE_LIST pAttr = NULL;
    SIZE_T dwBufLen = 0;
    DWORD dwMitigationPolicy = PROCESS_CREATION_MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON;
    STARTUPINFOEX startInfo = { 0 };
    PROCESS_INFORMATION procInfo = { 0 };
    DWORD dwExitCode = 0;

    if (InitializeProcThreadAttributeList(NULL, 1, 0, &dwBufLen) || GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
        res = GetLastError();
        _ftprintf(stderr, TEXT("Error: unable to get InitializeProcThreadAttributeList()'s required buffer length, code %u\n"), res);
        goto cleanup;
    }
    pAttr = (PPROC_THREAD_ATTRIBUTE_LIST)safe_alloc(dwBufLen);
    if (!InitializeProcThreadAttributeList(pAttr, 1, 0, &dwBufLen)) {
        res = GetLastError();
        _ftprintf(stderr, TEXT("Error: InitializeProcThreadAttributeList() failed with code %d\n"), res);
        goto cleanup;
    }
    if (!UpdateProcThreadAttribute(pAttr, 0, PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY, &dwMitigationPolicy, sizeof(dwMitigationPolicy), NULL, NULL)) {
        res = GetLastError();
        _ftprintf(stderr, TEXT("Error: UpdateProcThreadAttribute() failed with code %d\n"), res);
        goto cleanup;
    }

    ZeroMemory(&startInfo, sizeof(startInfo));
    ZeroMemory(&procInfo, sizeof(procInfo));
    startInfo.lpAttributeList = pAttr;
    startInfo.StartupInfo.cb = sizeof(startInfo);

    if (!CreateProcess(argv[1], NULL, NULL, NULL, FALSE, EXTENDED_STARTUPINFO_PRESENT, NULL, NULL, (STARTUPINFO*)&startInfo, &procInfo)) {
        res = GetLastError();
        _ftprintf(stderr, TEXT("Error: CreateProcess() failed with code %d\n"), res);
        goto cleanup;
    }

    _tprintf(TEXT(" [.] Child process created: pid %lu\n"), procInfo.dwProcessId);

    WaitForSingleObject(procInfo.hProcess, INFINITE);

    if (!GetExitCodeProcess(procInfo.hProcess, &dwExitCode)) {
        res = GetLastError();
        _ftprintf(stderr, TEXT("Error: GetExitCodeProcess() failed with code %d\n"), res);
    } else {
        _tprintf(TEXT(" [.] Child process exited with code 0x%08lX\n"), dwExitCode);
    }

cleanup:
    _tprintf(TEXT(" [.] All done, return code %d\n"), res);
    return res;
}
