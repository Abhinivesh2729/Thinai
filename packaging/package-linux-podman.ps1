# Builds the Linux packages from Windows inside an Ubuntu 22.04 container
# (older glibc, so the binary runs on most current distros). Output lands in dist/.
# Needs Podman with a running machine.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$flutterVersion = ((flutter --version --machine | ConvertFrom-Json).frameworkVersion)
New-Item -ItemType Directory -Force (Join-Path $root 'dist') | Out-Null

# The source is copied into the container (minus host build output) so the
# Windows .dart_tool/ and build/ are never touched.
$script = @"
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl git unzip xz-utils zip clang g++ cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev libgomp1 >/dev/null
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$flutterVersion-stable.tar.xz | tar -xJ -C /opt
git config --global --add safe.directory '*'
export PATH=/opt/flutter/bin:`$PATH
flutter config --no-analytics >/dev/null
mkdir /work
tar -C /src --exclude=./build --exclude=./.dart_tool --exclude=./dist --exclude=./android --exclude=./.git -cf - . | tar -C /work -xf -
cd /work
flutter pub get
bash packaging/package-linux.sh
cp dist/* /out/
"@
podman run --rm -v "${root}:/src:ro" -v "$(Join-Path $root 'dist'):/out" docker.io/library/ubuntu:22.04 bash -c ($script -replace "`r", '')
if ($LASTEXITCODE -ne 0) { throw 'Linux build failed' }
