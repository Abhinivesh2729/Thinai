; Inno Setup script for ThinaiSetup.exe. Built in CI (.github/workflows/windows.yml):
;   ISCC windows\installer\thinai.iss /DAppVersion=2.6.2 /DSourceDir=<release bundle>
;
; Per-user install: no admin prompt, lands in %LOCALAPPDATA%\Programs\Thinai.
; Models and chats live in the user's app-data folders, not here, so an
; uninstall or upgrade never deletes them.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\installer"
#endif

[Setup]
AppId={{8DE29292-463D-4F88-BB6E-7FF192FA6BBE}
AppName=Thinai
AppVersion={#AppVersion}
AppVerName=Thinai {#AppVersion}
AppPublisher=ATmega Software Technologies
AppPublisherURL=https://github.com/Abhinivesh2729/Thinai
DefaultDirName={localappdata}\Programs\Thinai
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir={#OutputDir}
OutputBaseFilename=ThinaiSetup-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\thinai.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Thinai"; Filename: "{app}\thinai.exe"
Name: "{autodesktop}\Thinai"; Filename: "{app}\thinai.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\thinai.exe"; Description: "Open Thinai"; Flags: nowait postinstall skipifsilent
