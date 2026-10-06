# Releasing Thinai

One GitHub Actions workflow runs, and only when a release ships. Everything else is done locally.

## Play Store release

1. Create a branch named after the version, e.g. `v2.3.11`, and bump `version:` in `pubspec.yaml` if needed.
2. Open a pull request from that branch into `release` and merge it.
3. **Release → Play Store (draft)** (`.github/workflows/release-play.yml`) runs. It does analyze, unit tests, an arm64 app bundle, and a **draft** on Play's production track. Watch it on the Actions tab; the run summary shows the version and build number.
4. In Play Console, open Thinai → Production, find the draft, and press **Review and roll out**. Nothing reaches users before this.

Cost: about 20 of the org's 2,000 free Actions minutes per release. No other workflow runs, so pushes to `Dev` or version branches cost nothing. To rerun without a new merge: Actions → *Release → Play Store (draft)* → *Run workflow*.

## Firebase testers (local)

```
scripts/firebase-distribute.sh "optional release notes"
```

Builds a signed arm64 release APK on your machine (~15 min the first time) and sends it to the Firebase group `testers`. It needs `android/key.properties` and the keystore locally, and a logged-in `firebase` CLI.

- **Add testers:** [Firebase console](https://console.firebase.google.com/project/thinai-7a931/appdistribution) → App Distribution → Testers & Groups → `testers` → **Add testers**. Or: `firebase appdistribution:testers:add someone@example.com --group-alias testers --project thinai-7a931`
- **Remove testers:** same page, or `firebase appdistribution:testers:remove someone@example.com --group-alias testers --project thinai-7a931`. Removed testers keep builds they already installed.

## Version numbers

- **Version name** (what users see) comes from `version:` in `pubspec.yaml`.
- **Build number / versionCode** is `100 + number of commits`, both in CI and in the local script. It rises with every commit, so Play never rejects a reused code. The `+N` in `pubspec.yaml` is ignored.

## Good to know

- Builds are arm64 only. 32-bit ARM phones and x86_64 devices don't get new versions.
- Tests tagged `native` don't run in CI; run them on a device with `flutter test --tags native`.
- Flutter is pinned to 3.47.4 in `release-play.yml`.
- **GPU backends (since v2.3.11).** The Android native build compiles llama.cpp's Vulkan and OpenCL backends. It needs, on the build machine:
  - `glslc` from the NDK's `shader-tools/<host>/`. The hook finds it automatically and fails loudly if it's missing.
  - Python 3, to embed the OpenCL kernels.
  - A host C/C++ compiler, to build `vulkan-shaders-gen`.

  GitHub's Ubuntu runners have all three. The Vulkan and OpenCL headers are vendored under `third_party/fllama/src/third_party/`. Expect a few more minutes of native build and a ~62 MB arm64 APK.
- **Installing a local or Firebase build on a phone that has the Play Store version fails** with a signature mismatch, because Play re-signs with its own key. Uninstall the Play version first; this wipes the app's data.
- CI secrets live in repo Settings → Secrets and variables → Actions: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`.
