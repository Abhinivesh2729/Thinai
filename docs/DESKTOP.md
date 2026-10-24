# Thinai on desktop (Windows, Linux, macOS)

The desktop app is the same Flutter codebase as Android (see [ADR-001](decisions/ADR-001-desktop-from-flutter-codebase.md)). Packaging scripts live in `packaging/` and write their output to `dist/`, which is git-ignored.

| OS | Files | Script | Where it can run |
|---|---|---|---|
| Windows | `thinai-v<version>-windows-x64-setup.exe`, `.msi`, `.zip` | `packaging/package-windows.ps1` | Windows |
| Linux | `thinai-v<version>-linux-x64.deb`, `.tar.gz` | `packaging/package-linux.sh` | Linux, or Windows through `packaging/package-linux-podman.ps1` |
| macOS | `thinai-v<version>-macos.dmg`, `.zip` | `packaging/package-macos.sh` | macOS with Xcode |

`<version>` is the `version:` in `pubspec.yaml` without the build number (`2.4.0+13` gives `v2.4.0`).

## Windows

Requirements:
- Visual Studio with the "Desktop development with C++" workload
- Developer Mode on (Settings > System > Advanced > For developers). Flutter needs it for plugin symlinks; without it the build stops with "Building with plugins requires symlink support".
- WiX 5 and its extensions, for the installers:
  ```powershell
  dotnet tool install -g wix --version 5.0.1
  wix extension add -g WixToolset.UI.wixext/5.0.1 WixToolset.Util.wixext/5.0.1 WixToolset.BootstrapperApplications.wixext/5.0.1
  ```

Build and package:
```powershell
./packaging/package-windows.ps1            # flutter build windows --release, then package
./packaging/package-windows.ps1 -SkipBuild # package the existing build
```

What the installers do:
- **`-setup.exe`** shows the license, installs the MSI, and offers a **Launch** button when it finishes.
- **`.msi`** lets you choose the install folder (default `C:\Program Files\Thinai`) and has a **Launch Thinai** checkbox on its last page, ticked by default.
- Both add a Start menu shortcut and a desktop shortcut with the Thinai icon.
- **Upgrades:** installing a newer build over an existing install replaces it in place, and a running Thinai is asked to close first. The installers carry the build number (`2.4.0.13`). The setup `.exe` compares all four parts. Windows Installer (the `.msi`) ignores the fourth, so builds of the same `x.y.z` are allowed to replace each other. That means the `.msi` does **not** stop you from installing an *older* build of the same `x.y.z`; bump `x.y.z` for releases.
- **Ship one installer per PC.** Use the setup `.exe` as the recommended download. Installing with the `.exe` and later with the `.msi` (or the other way round) can leave two entries in Apps & features.
- **`.zip`** is portable: unzip and run `thinai.exe`.

## Linux

On Ubuntu 22.04 or newer (or CI):
```bash
sudo apt-get install -y clang g++ cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
bash packaging/package-linux.sh
```
`g++` is required even with clang installed: the llama.cpp build in `third_party/fllama` uses the `x86_64-linux-gnu` toolchain file, which expects GCC.

From Windows, with Podman running:
```powershell
./packaging/package-linux-podman.ps1
```
This copies the source into an Ubuntu 22.04 container (the older glibc lets the binary run on most current distros), installs the same Flutter version as the host, builds, and copies the packages to `dist/`. The host's `build/` and `.dart_tool/` are not touched.

The `.deb` installs to `/opt/thinai`, puts `thinai` on the PATH, and adds a launcher entry with the icon. The `.tar.gz` is portable: extract it and run `thinai/thinai`.

## macOS

On a Mac with Xcode:
```bash
bash packaging/package-macos.sh
```
The `.dmg` has the usual drag-to-Applications layout; the `.zip` holds the `.app`.

The release build's sandbox entitlements allow outgoing network (model downloads), incoming network (the API server) and user-selected files (importing models and attachments). See `macos/Runner/Release.entitlements`.

The app is **not signed with a Developer ID or notarised**, so Gatekeeper warns on first open (right-click > Open). Sign and notarise before a public release.

## CI

`.github/workflows/desktop-build.yml` builds all three platforms and uploads the packages as workflow artifacts. It runs only when started by hand (Actions > Desktop Build > Run workflow), so it adds no cost to ordinary pushes; see [CICD.md](CICD.md) for how Actions minutes are budgeted.

## Desktop behaviour

- The window opens maximized on every OS (a Windows shortcut set to "Run: Minimized" is honoured).
- One copy runs at a time: launching Thinai again brings the open window forward (Windows: a per-session named mutex; Linux: a unique GtkApplication; macOS apps are single-instance already).
- The API server runs only while the app window is open: desktop has no foreground service.
- The landing screen greets the signed-in OS account by name ("Welcome, Kalidas" / "வணக்கம், Kalidas"); Android shows the greeting without a name.
- Strings that name the hardware say "computer" (கணினி) instead of "phone" (கைப்பேசி).
- App data (settings, chats, models) is stored under the OS app-data folder, e.g. `%APPDATA%\in.atmega\Thinai` on Windows.

## Native chat tests

`test/chat_native_test.dart` runs real llama.cpp generation, tool calls included. It is skipped by default only because it downloads a 469 MB model:
```bash
THANAI_NATIVE_CHAT=1 flutter test test/chat_native_test.dart --tags native
```
Run it after any change to `third_party/fllama`: it is what caught the Windows divide-by-zero and the callback use-after-free (see the changelog).

## Known limitations

- **Windows runs llama.cpp on the CPU at baseline SSE2 only:** the build has `GGML_NATIVE`, `GGML_AVX` and `GGML_AVX2` off, and Vulkan is off when the Vulkan SDK is not installed at build time. Expect slow generation.
- Linux builds are CPU-only.
- Builds from the `Desktop Build` workflow are CPU-only on Windows too (the runner has no Vulkan SDK), while a local build with the SDK installed gets Vulkan. Expect different speed from the two.
- LAN mode is plain HTTP: anyone on the same network can read the bearer token in transit. Use it only on networks you trust.
- The UI is still phone-shaped (bottom navigation bar) on large windows.
- No desktop updater yet; the in-app updater is Android/Play only.
- Untested on desktop so far: file picking, sharing.
