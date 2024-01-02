#include <windows.h>
#include <processthreadsapi.h>
#include <WinBase.h>
// https://stackoverflow.com/questions/76930541/createprocessw-with-extended-startupinfo-present-flag-returns-error-code-87
// with corrections.
// Note: Must enable inheritance on each handle in attribute list to prevent
// INVALID_PARAMETER error in CreateProcessW.
#include <iostream>
using namespace std;

void TestFunctionW()
{
    STARTUPINFOEXW startup_info = { 0 };
    PROCESS_INFORMATION process_info = { 0 };

    SECURITY_ATTRIBUTES saAttr;

    // Set the bInheritHandle flag so pipe handles are inherited.
    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
    saAttr.bInheritHandle = TRUE;
    saAttr.lpSecurityDescriptor = NULL;

    HANDLE          m_hChildStd_OUT_Rd;
    HANDLE          m_hChildStd_OUT_Wr;

    // Create a pipe for the child process's STDOUT. (m_hChildStd_OUT_Wr->m_hChildStd_OUT_Rd)
    if (!CreatePipe(&m_hChildStd_OUT_Rd, &m_hChildStd_OUT_Wr, &saAttr, 0)) {
        std::cerr << "CreatePipe Failed" << endl;
    }

    // Ensure the read handle to the pipe for STDOUT is not inherited.
    if (!SetHandleInformation(m_hChildStd_OUT_Rd, HANDLE_FLAG_INHERIT, 0)){
        std::cerr << "SetHandleInformation Failed" << endl;
    }
    // Ensure the write handle to the pipe for STDOUT is not inherited.
    if (!SetHandleInformation(m_hChildStd_OUT_Wr, HANDLE_FLAG_INHERIT, 1)){
        std::cerr << "SetHandleInformation Failed" << endl;
    }

    startup_info.StartupInfo.hStdError = NULL;
    startup_info.StartupInfo.hStdOutput = m_hChildStd_OUT_Wr;
    startup_info.StartupInfo.hStdInput = NULL;
    startup_info.StartupInfo.dwFlags |= STARTF_USESTDHANDLES;


    // Newstuff relating to handle lists
    BOOL fSuccess = true;
    BOOL fInitialized = FALSE;
    SIZE_T size = 0;
    LPPROC_THREAD_ATTRIBUTE_LIST lpAttributeList = NULL;

    int cHandlesToInherit = 1;
    HANDLE rgHandlesToInherit[] = { m_hChildStd_OUT_Wr };

    if (fSuccess) {
        fSuccess = InitializeProcThreadAttributeList(NULL, 1, 0, &size) || GetLastError() == ERROR_INSUFFICIENT_BUFFER;
    }
    if (fSuccess) {
        lpAttributeList = reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(HeapAlloc(GetProcessHeap(), 0, size));
        fSuccess = lpAttributeList != NULL;
    }
    if (fSuccess) {
        fSuccess = InitializeProcThreadAttributeList(lpAttributeList, 1, 0, &size);
    }
    if (fSuccess) {
        fInitialized = TRUE;
        fSuccess = UpdateProcThreadAttribute(lpAttributeList,
            0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
            rgHandlesToInherit,
            cHandlesToInherit * sizeof(HANDLE), NULL, NULL);
    }

    if (!fSuccess) {
        cerr << "Handle list stuff failed" << endl;
        exit(-1);
    }

    startup_info.lpAttributeList = lpAttributeList;

    // cerr << "Handle stuff succeeded.." << endl;
    startup_info.StartupInfo.cb = sizeof(startup_info);

    DWORD flags = EXTENDED_STARTUPINFO_PRESENT;
    //DWORD flags = 0;

    std::wstring cmd(L"ping.exe");
    BOOL ret = CreateProcessW(NULL, (LPWSTR)cmd.c_str(), NULL, NULL, TRUE, flags, NULL, NULL, (LPSTARTUPINFOW)&startup_info, &process_info);
    if (!ret)
    {
        DWORD err = GetLastError();
	std::cerr << "Failed: code " << err << std::endl;
    }
}

int main(int argc, char** argv)
{
    TestFunctionW();
}
