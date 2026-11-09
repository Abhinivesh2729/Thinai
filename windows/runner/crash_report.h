#ifndef RUNNER_CRASH_REPORT_H_
#define RUNNER_CRASH_REPORT_H_

// Native crash evidence for test builds that run where no debugger can.
//
// * stderr (llama.cpp / ggml messages, including GGML_ASSERT text) goes to
//   <logs>\native.log; the previous run's copy is kept as native.prev.log.
// * An unhandled exception or abort() writes <logs>\crash.txt with the
//   exception code and a module+offset stack. The Dart side folds it into
//   the app log on the next launch, so "Copy diagnostics" carries it.
//
// <logs> is %APPDATA%\ATmega Software Technologies\Thinai\logs, the same
// folder path_provider gives the Dart code (company/product from Runner.rc).
void InstallCrashReporting();

#endif  // RUNNER_CRASH_REPORT_H_
