; R.A.I.K.O Desktop Windows Installer
; Built with Inno Setup 6.x

[Setup]
AppName=R.A.I.K.O Desktop
AppVersion=0.1.0
AppPublisher=R.A.I.K.O
AppPublisherURL=https://github.com/methan6427/R.A.I.K.O
AppSupportURL=https://github.com/methan6427/R.A.I.K.O/issues
AppUpdatesURL=https://github.com/methan6427/R.A.I.K.O/releases

DefaultDirName={autopf}\R.A.I.K.O Desktop
DefaultGroupName=R.A.I.K.O Desktop
OutputDir=dist
OutputBaseFilename=raiko-desktop-setup-0.1.0
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\desktop.exe
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\apps\desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\R.A.I.K.O Desktop"; Filename: "{app}\desktop.exe"
Name: "{group}\Uninstall R.A.I.K.O Desktop"; Filename: "{uninstallexe}"
Name: "{commondesktop}\R.A.I.K.O Desktop"; Filename: "{app}\desktop.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\desktop.exe"; Description: "Launch R.A.I.K.O Desktop"; Flags: postinstall nowait skipifsilent
