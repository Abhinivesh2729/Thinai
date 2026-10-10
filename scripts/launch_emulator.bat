@echo off
if exist "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" (
    start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_API_37.0
) else if defined ANDROID_HOME (
    start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd Medium_Phone_API_37.0
) else (
    start "" emulator -avd Medium_Phone_API_37.0
)
