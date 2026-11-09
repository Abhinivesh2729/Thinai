#include "crash_report.h"

#include <windows.h>
#include <dbghelp.h>
#include <shlobj.h>

#include <csignal>
#include <cstdio>
#include <cwchar>
#include <string>

namespace {

wchar_t g_crash_path[MAX_PATH] = {};
volatile LONG g_writing = 0;

std::wstring LogsDir() {
  PWSTR roaming = nullptr;
  if (FAILED(::SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr,
                                    &roaming))) {
    return L"";
  }
  std::wstring dir(roaming);
  ::CoTaskMemFree(roaming);
  dir += L"\\ATmega Software Technologies\\Thinai\\logs";
  ::SHCreateDirectoryExW(nullptr, dir.c_str(), nullptr);
  return dir;
}

const wchar_t* BaseName(const wchar_t* path) {
  const wchar_t* slash = wcsrchr(path, L'\\');
  return slash ? slash + 1 : path;
}

void WriteFrame(FILE* f, HANDLE process, int index, DWORD64 pc) {
  HMODULE module = nullptr;
  wchar_t name[MAX_PATH] = L"?";
  if (::GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           reinterpret_cast<LPCWSTR>(pc), &module)) {
    ::GetModuleFileNameW(module, name, MAX_PATH);
  }
  alignas(SYMBOL_INFO) char buffer[sizeof(SYMBOL_INFO) + 256] = {};
  auto* symbol = reinterpret_cast<SYMBOL_INFO*>(buffer);
  symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
  symbol->MaxNameLen = 255;
  DWORD64 displacement = 0;
  const bool named = ::SymFromAddr(process, pc, &displacement, symbol) != 0;
  fwprintf(f, L"#%02d %ls+0x%llx  %hs+0x%llx\n", index, BaseName(name),
           static_cast<unsigned long long>(pc - reinterpret_cast<DWORD64>(module)),
           named ? symbol->Name : "", static_cast<unsigned long long>(displacement));
}

void WriteReport(const char* reason, DWORD code, void* address,
                 CONTEXT* context) {
  if (InterlockedExchange(&g_writing, 1) != 0) return;
  FILE* f = nullptr;
  if (_wfopen_s(&f, g_crash_path, L"w") != 0 || f == nullptr) return;
  SYSTEMTIME now;
  ::GetLocalTime(&now);
  fprintf(f, "%s code=0x%08lX address=%p thread=%lu at %04d-%02d-%02d %02d:%02d:%02d\n",
          reason, code, address, ::GetCurrentThreadId(), now.wYear, now.wMonth,
          now.wDay, now.wHour, now.wMinute, now.wSecond);
  HANDLE process = ::GetCurrentProcess();
  ::SymSetOptions(SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
  ::SymInitialize(process, nullptr, TRUE);
  if (context != nullptr) {
    CONTEXT ctx = *context;
    STACKFRAME64 frame = {};
    frame.AddrPC.Offset = ctx.Rip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = ctx.Rbp;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = ctx.Rsp;
    frame.AddrStack.Mode = AddrModeFlat;
    for (int i = 0; i < 48; ++i) {
      if (!::StackWalk64(IMAGE_FILE_MACHINE_AMD64, process, ::GetCurrentThread(),
                         &frame, &ctx, nullptr, ::SymFunctionTableAccess64,
                         ::SymGetModuleBase64, nullptr) ||
          frame.AddrPC.Offset == 0) {
        break;
      }
      WriteFrame(f, process, i, frame.AddrPC.Offset);
    }
  } else {
    void* frames[48];
    const USHORT n = ::RtlCaptureStackBackTrace(0, 48, frames, nullptr);
    for (USHORT i = 0; i < n; ++i) {
      WriteFrame(f, process, i, reinterpret_cast<DWORD64>(frames[i]));
    }
  }
  fclose(f);
}

LONG WINAPI OnUnhandledException(EXCEPTION_POINTERS* info) {
  WriteReport("exception", info->ExceptionRecord->ExceptionCode,
              info->ExceptionRecord->ExceptionAddress, info->ContextRecord);
  return EXCEPTION_CONTINUE_SEARCH;
}

void OnAbort(int) {
  // GGML_ASSERT and friends end in abort(); their message is already in
  // native.log, this records where.
  WriteReport("abort", 0, nullptr, nullptr);
  fflush(stderr);
}

}  // namespace

void InstallCrashReporting() {
  const std::wstring dir = LogsDir();
  if (dir.empty()) return;
  wcsncpy_s(g_crash_path, (dir + L"\\crash.txt").c_str(), _TRUNCATE);

  // Keep the last run's native log next to this one.
  const std::wstring native = dir + L"\\native.log";
  const std::wstring previous = dir + L"\\native.prev.log";
  ::MoveFileExW(native.c_str(), previous.c_str(), MOVEFILE_REPLACE_EXISTING);
  // A GUI app has no stderr; give llama.cpp's messages somewhere to land.
  // Set THINAI_CONSOLE_LOGS to keep them on the console instead (flutter run).
  if (::GetEnvironmentVariableW(L"THINAI_CONSOLE_LOGS", nullptr, 0) == 0) {
    FILE* ignored = nullptr;
    if (_wfreopen_s(&ignored, native.c_str(), L"w", stderr) == 0) {
      setvbuf(stderr, nullptr, _IONBF, 0);
    }
  }

  ::SetUnhandledExceptionFilter(OnUnhandledException);
  signal(SIGABRT, OnAbort);
  _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
}
