# Packages the Windows release build as dist/thinai-v<version>-windows-x64.{zip,msi} and
# dist/thinai-v<version>-windows-x64-setup.exe.
# Needs the WiX dotnet tool (5.x) with the UI, Util and BootstrapperApplications extensions:
#   dotnet tool install -g wix
#   wix extension add -g WixToolset.UI.wixext/5.0.1 WixToolset.Util.wixext/5.0.1 WixToolset.BootstrapperApplications.wixext/5.0.1
param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

# pubspec "version: 2.4.0+13": files are named v2.4.0, installers carry 2.4.0.13.
# The setup .exe compares all four parts; Windows Installer ignores the fourth,
# so the MSI relies on AllowSameVersionUpgrades within one x.y.z.
$m = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)\+?([0-9]*)').Matches[0]
$version = $m.Groups[1].Value
$installerVersion = if ($m.Groups[2].Value) { "$version.$($m.Groups[2].Value)" } else { $version }
$name = "thinai-v$version-windows-x64"

if (-not $SkipBuild) {
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }
}
$release = Join-Path $root 'build\windows\x64\runner\Release'
if (-not (Test-Path "$release\thinai.exe")) { throw "No build at $release" }
if (-not (Test-Path "$release\fllama.dll")) { throw 'fllama.dll missing from the build; the app could not load models' }

$dist = Join-Path $root 'dist'
$work = Join-Path $root 'build\packaging'
New-Item -ItemType Directory -Force $dist, $work | Out-Null

# ZIP: portable, unzip and run thinai.exe
$zip = Join-Path $dist "$name.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path "$release\*" -DestinationPath $zip

# License page for both installers, from LICENSE as plain RTF
$rtf = Join-Path $work 'license.rtf'
$body = (Get-Content LICENSE -Encoding utf8 | ForEach-Object {
    $line = $_ -replace '\\', '\\' -replace '\{', '\{' -replace '\}', '\}'
    # RTF is 7-bit: anything else goes out as \uN? (N = signed UTF-16 unit)
    -join ($line.ToCharArray() | ForEach-Object {
        $n = [int]$_
        if ($n -lt 128) { $_ } else { '\u' + $(if ($n -gt 32767) { $n - 65536 } else { $n }) + '?' }
      })
  }) -join "\par`n"
"{\rtf1\ansi\deff0{\fonttbl{\f0 Segoe UI;}}\fs18`n$body\par`n}" | Set-Content $rtf -Encoding ascii

$icon = Join-Path $root 'windows\runner\resources\app_icon.ico'
$msi = Join-Path $dist "$name.msi"
wix build packaging\windows\thinai.wxs -arch x64 -ext WixToolset.UI.wixext -ext WixToolset.Util.wixext `
  -d Version=$installerVersion -d SourceDir=$release -d IconFile=$icon -d LicenseRtf=$rtf `
  -o $msi
if ($LASTEXITCODE -ne 0) { throw 'MSI build failed' }

$exe = Join-Path $dist "$name-setup.exe"
wix build packaging\windows\bundle.wxs -arch x64 -ext WixToolset.BootstrapperApplications.wixext `
  -d Version=$installerVersion -d MsiFile=$msi -d IconFile=$icon -d LicenseRtf=$rtf `
  -o $exe
if ($LASTEXITCODE -ne 0) { throw 'Setup .exe build failed' }

Remove-Item (Join-Path $dist '*.wixpdb') -ErrorAction SilentlyContinue
Get-ChildItem $dist -Filter "$name*" | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } }
