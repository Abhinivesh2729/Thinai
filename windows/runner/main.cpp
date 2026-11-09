#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>
#include <cwchar>

#include "crash_report.h"
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // One Thinai at a time: a second launch brings the open window forward
  // instead of starting another engine (and another model in RAM). The smoke
  // test passes --smoke and is allowed to run beside a normal instance.
  const bool smoke = command_line != nullptr &&
                     wcsstr(command_line, L"--smoke") != nullptr;
  HANDLE single_instance = nullptr;
  if (!smoke) {
    single_instance =
        ::CreateMutexW(nullptr, TRUE, L"Local\\in.atmega.thinai.desktop");
    if (::GetLastError() == ERROR_ALREADY_EXISTS) {
      HWND existing =
          ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Thinai");
      if (existing != nullptr) {
        if (::IsIconic(existing)) ::ShowWindow(existing, SW_RESTORE);
        ::ShowWindow(existing, SW_SHOW);
        ::SetForegroundWindow(existing);
      }
      return EXIT_SUCCESS;
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  InstallCrashReporting();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Centred on the primary monitor's work area. Win32Window scales these
  // logical sizes by the monitor's DPI.
  Win32Window::Size size(1240, 800);
  RECT work{};
  ::SystemParametersInfoW(SPI_GETWORKAREA, 0, &work, 0);
  const UINT dpi = ::GetDpiForSystem();
  const double scale = dpi / 96.0;
  const int work_w = static_cast<int>((work.right - work.left) / scale);
  const int work_h = static_cast<int>((work.bottom - work.top) / scale);
  if (work_w > 0 && work_h > 0) {
    size.width = std::min(size.width, static_cast<unsigned int>(work_w));
    size.height = std::min(size.height, static_cast<unsigned int>(work_h));
  }
  const int left = static_cast<int>(work.left / scale) +
                   (work_w - static_cast<int>(size.width)) / 2;
  const int top = static_cast<int>(work.top / scale) +
                  (work_h - static_cast<int>(size.height)) / 2;
  Win32Window::Point origin(static_cast<unsigned int>(std::max(0, left)),
                            static_cast<unsigned int>(std::max(0, top)));
  if (!window.Create(L"Thinai", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance != nullptr) ::CloseHandle(single_instance);
  return EXIT_SUCCESS;
}
