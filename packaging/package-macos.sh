#!/usr/bin/env bash
# Packages the macOS release build as dist/thinai-v<version>-macos.{dmg,zip}.
# Run on a Mac with Xcode. Pass --skip-build to package an existing build.
# shortcut: the app is ad-hoc signed only, so Gatekeeper warns on first open
# (right-click > Open). Sign with a Developer ID and notarise before a public release.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
name="thinai-v$version-macos"

[ "${1:-}" = --skip-build ] || flutter build macos --release
app=build/macos/Build/Products/Release/Thinai.app
test -d "$app" || { echo "No build at $app" >&2; exit 1; }

mkdir -p dist
rm -f "dist/$name.zip" "dist/$name.dmg"

# zip: ditto keeps symlinks and extended attributes inside the .app
ditto -c -k --keepParent "$app" "dist/$name.zip"

# dmg: drag Thinai into Applications
stage=build/packaging/dmg
rm -rf "$stage" && mkdir -p "$stage"
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname Thinai -srcfolder "$stage" -ov -format UDZO "dist/$name.dmg"

ls -la dist/"$name".*
