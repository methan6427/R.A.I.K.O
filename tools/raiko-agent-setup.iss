; R.A.I.K.O Agent Windows Installer
; Built with Inno Setup 6.x (https://jrsoftware.org/isdl.php)

[Setup]
AppName=R.A.I.K.O Agent
AppVersion=0.1.0
AppPublisher=R.A.I.K.O
AppPublisherURL=https://github.com/methan6427/R.A.I.K.O
AppSupportURL=https://github.com/methan6427/R.A.I.K.O/issues
AppUpdatesURL=https://github.com/methan6427/R.A.I.K.O/releases

DefaultDirName={pf}\R.A.I.K.O Agent
DefaultGroupName=R.A.I.K.O Agent
OutputDir=dist
OutputBaseFilename=raiko-agent-setup-0.1.0
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\raiko-agent.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "dist\raiko-agent.exe"; DestDir: "{app}"; Flags: ignoreversion

; Config template
Source: "config.example.json"; DestDir: "{app}"; DestName: "config.json"; Flags: onlyifdoesntexist

; Setup scripts
Source: "setup-gui.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "setup.ps1"; DestDir: "{app}"; Flags: ignoreversion

; README
Source: "README-AGENT.txt"; DestDir: "{app}"; Flags: isreadme ignoreversion

[Icons]
Name: "{group}\R.A.I.K.O Agent Setup"; Filename: "powershell"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\setup-gui.ps1"""; IconFilename: "{app}\raiko-agent.exe"
Name: "{group}\Run Agent"; Filename: "{app}\raiko-agent.exe"; IconFilename: "{app}\raiko-agent.exe"
Name: "{group}\Edit Config"; Filename: "notepad.exe"; Parameters: "{app}\config.json"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"
Name: "{commondesktop}\R.A.I.K.O Agent Setup"; Filename: "powershell"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\setup-gui.ps1"""; IconFilename: "{app}\raiko-agent.exe"; Tasks: desktopicon

[Run]
; Show setup GUI after install
Filename: "powershell"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\setup-gui.ps1"""; Description: "Run setup wizard now"; Flags: postinstall nowait

[UninstallDelete]
Type: files; Name: "{app}\config.json"
Type: dirifempty; Name: "{app}"
