#!/usr/bin/env bash
# Builds a signed arm64 release APK on this machine and sends it to the Firebase App Distribution group "testers".
# Usage: scripts/firebase-distribute.sh ["optional release notes"]
set -euo pipefail
cd "$(dirname "$0")/.."

# llama.cpp subprojects don't configure with CMake 4, so use the Android SDK's 3.22.1.
export PATH="$HOME/Library/Android/sdk/cmake/3.22.1/bin:$PATH"

version=$(sed -nE 's/^version: *([^+ ]+).*/\1/p' pubspec.yaml)
code=$((100 + $(git rev-list --count HEAD)))
notes="${1:-$version ($code) · $(git log -1 --format=%s) · $(git rev-parse --short HEAD)}"

flutter build apk --release --target-platform android-arm64 --build-number="$code"

firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:677696498407:android:bade85b7e85f247a95d042 \
  --groups testers \
  --release-notes "$notes"
