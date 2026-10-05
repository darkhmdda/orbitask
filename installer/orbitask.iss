#ifndef MyAppVersion
  #error "MyAppVersion must be provided by the build script"
#endif

#define MyAppName "Orbitask"
#define MyAppPublisher "darkh"
#define MyAppExeName "orbitask.exe"

[Setup]
; Keep this AppId permanently unchanged so upgrades replace the same installation.
AppId={{F3B7419E-0B2F-4A87-A86D-ORBITASK090}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Orbitask
DefaultGroupName=Orbitask
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=Orbitask-v{#MyAppVersion}-windows-setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\orbitask.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Orbitask"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Orbitask"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"; Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir Orbitask"; Flags: nowait postinstall skipifsilent
