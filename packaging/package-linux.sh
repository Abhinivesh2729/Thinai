#!/usr/bin/env bash
# Packages the Linux release build as dist/thinai-v<version>-linux-x64.{tar.gz,deb}.
# Run on Linux (or via packaging/package-linux-podman.ps1 from Windows).
# Pass --skip-build to package an existing build.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
name="thinai-v$version-linux-x64"

[ "${1:-}" = --skip-build ] || flutter build linux --release
bundle=build/linux/x64/release/bundle
test -x "$bundle/thinai" || { echo "No build at $bundle" >&2; exit 1; }
test -e "$bundle/lib/libfllama.so" || { echo "libfllama missing from the build; the app could not load models" >&2; exit 1; }

mkdir -p dist

# tar.gz: portable, extract and run thinai/thinai
tar -czf "dist/$name.tar.gz" -C "$(dirname "$bundle")" --transform 's,^bundle,thinai,' bundle

# .deb: app in /opt/thinai, `thinai` on PATH, launcher entry + icon
deb=build/packaging/deb
rm -rf "$deb"
mkdir -p "$deb/DEBIAN" "$deb/opt" "$deb/usr/bin" \
  "$deb/usr/share/applications" "$deb/usr/share/icons/hicolor/512x512/apps"
cp -r "$bundle" "$deb/opt/thinai"
ln -s /opt/thinai/thinai "$deb/usr/bin/thinai"
cp packaging/linux/in.atmega.thinai.desktop "$deb/usr/share/applications/"
cp packaging/linux/thinai.png "$deb/usr/share/icons/hicolor/512x512/apps/thinai.png"
cat > "$deb/DEBIAN/control" <<EOF
Package: thinai
Version: $version
Architecture: amd64
Maintainer: Thinai <https://github.com/Abhinivesh2729/Thinai>
Depends: libgtk-3-0, libegl1, libgles2, libgomp1
Section: utils
Priority: optional
Homepage: https://github.com/Abhinivesh2729/Thinai
Description: Private, offline LLM chat with a local OpenAI/Ollama-compatible API
EOF
dpkg-deb --build --root-owner-group "$deb" "dist/$name.deb"

ls -la dist/"$name".*
