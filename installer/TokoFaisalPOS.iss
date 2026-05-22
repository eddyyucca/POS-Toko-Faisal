#define AppName "Toko Faisal POS"
#define AppVersion "1.0.0"
#define AppPublisher "PT Fluxa Tritama Indonesia"
#define AppExeName "TokoFaisalPOS.exe"
#define SourceDir "C:\xampp\htdocs\desktop\desktop\build\windows\x64\runner\Release"
#define InstallerDir "C:\xampp\htdocs\desktop\desktop\installer"

[Setup]
AppId={{F4154A1-9B2C-4D3E-8F5A-6C7D8E9F0A1B}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} v{#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://fluxatritama.co.id
AppSupportURL=https://fluxatritama.co.id
AppCopyright=Copyright (C) 2026 PT Fluxa Tritama Indonesia
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir={#InstallerDir}\output
OutputBaseFilename=TokoFaisalPOS_Setup_v{#AppVersion}
SetupIconFile=C:\xampp\htdocs\desktop\desktop\windows\runner\resources\app_icon.ico
WizardStyle=classic
WizardImageFile={#InstallerDir}\wizard_large.bmp
WizardSmallImageFile={#InstallerDir}\wizard_small.bmp
WizardImageStretch=yes
WizardImageBackColor=$1C2B3A
Compression=lzma2/ultra64
SolidCompression=yes
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName}
VersionInfoCopyright=Copyright (C) 2026 PT Fluxa Tritama Indonesia

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Buat shortcut di Desktop"

[Files]
Source: "{#SourceDir}\desktop.exe";         DestDir: "{app}"; DestName: "{#AppExeName}"; Flags: ignoreversion
Source: "{#SourceDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\data\*";              DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}";           Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}";     Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Jalankan {#AppName} sekarang"; Flags: nowait postinstall skipifsilent
