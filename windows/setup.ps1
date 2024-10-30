#!/usr/bin/env pwsh

########################################################################################################################
##                                                                                                                    ##
##                                                     Functions                                                      ##
##                                                                                                                    ##
########################################################################################################################

function Write-Log {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Message,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug', 'Verbose')]
    [string]$Type = 'Info',
    [Parameter(Mandatory = $false)]
    [switch]$NoNewLine
  )

  $colors = @{
    Info    = 'White'
    Warning = 'Yellow'
    Error   = 'Red'
    Success = 'Green'
    Debug   = 'Cyan'
    Verbose = 'Gray'
  }

  $params = @{
    ForegroundColor = $colors[$Type]
    NoNewline       = $NoNewLine
  }

  Write-Host $Message @params
}
function Invoke-Silently {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [scriptblock]$ScriptBlock
  )

  $oldProgressPreference = $ProgressPreference
  $oldVerbosePreference = $VerbosePreference
  $oldInformationPreference = $InformationPreference
  $oldWarningPreference = $WarningPreference
  $oldErrorActionPreference = $ErrorActionPreference

  $ProgressPreference = 'SilentlyContinue'
  $VerbosePreference = 'SilentlyContinue'
  $InformationPreference = 'SilentlyContinue'
  $WarningPreference = 'SilentlyContinue'
  $ErrorActionPreference = 'SilentlyContinue'

  $null = & {
    & $ScriptBlock 2>&1 > $null
  } *> $null

  $ProgressPreference = $oldProgressPreference
  $VerbosePreference = $oldVerbosePreference
  $InformationPreference = $oldInformationPreference
  $WarningPreference = $oldWarningPreference
  $ErrorActionPreference = $oldErrorActionPreference
}

########################################################################################################################
##                                                                                                                    ##
##                                                  Start of Script                                                   ##
##                                                                                                                    ##
########################################################################################################################

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
if (-not ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  Write-Log "This script must be run as an administrator. Open the PowerShell console as an administrator and run this script again." -Type Error
  exit 1
}

$profileDirectoryPath = "$env:USERPROFILE\Documents\Powershell"
if (-not (Test-Path -Path $profileDirectoryPath)) {
  try {
    Write-Log "Creating PowerShell profile directory... " -Type Info -NoNewLine
    Invoke-Silently { New-Item -Path $profileDirectoryPath -ItemType Directory }
    Write-Log "Success" -Type Success
  }
  catch {
    Write-Log "Failed" -Type Error
  }
}

try {
  Write-Log "Downloading CTT's PowerShell profile... " -Type Info -NoNewLine
  Invoke-RestMethod `
    -Uri "https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1" `
    -OutFile $PROFILE
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Downloading personal PowerShell profile... " -Type Info -NoNewLine
  Invoke-WebRequest `
    -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/profile.ps1" `
    -OutFile "$profileDirectoryPath\profile.ps1"
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Installing 'Chocolatey'... " -Type Info -NoNewLine
  Invoke-Silently {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  }
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Installing 'Fira Code' and 'Fira Code Nerd Font'... " -Type Info -NoNewLine
  Invoke-Silently {
    choco install --confirm firacode
    choco install --confirm firacodenf
  }
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

$wingetPackageIds = @(
  "7zip.7zip",
  "AntibodySoftware.WizFile",
  "AntibodySoftware.WizTree",
  "AsaphaHalifa.AudioRelay",
  "BlenderFoundation.Blender",
  "Canonical.Ubuntu.2404",
  "DenoLand.Deno",
  "Discord.Discord",
  "Docker.DockerDesktop",
  "DuongDieuPhap.ImageGlass",
  "EpicGames.EpicGamesLauncher",
  "Figma.Figma",
  "Git.Git",
  "GitHub.cli",
  "GitHub.GitHubDesktop",
  "Guru3D.Afterburner",
  "JanDeDobbeleer.OhMyPosh",
  "JetBrains.Rider",
  "Logitech.GHUB",
  "MartiCliment.UniGetUI",
  "Microsoft.DotNet.SDK.8",
  "Microsoft.PowerShell",
  "Microsoft.PowerToys",
  "Microsoft.VisualStudio.2022.Community",
  "Microsoft.VisualStudioCode",
  "Microsoft.WSL",
  "Notion.Notion",
  "Notion.NotionCalendar",
  "Nvidia.GeForceExperience",
  "Oven-sh.Bun",
  "Proton.ProtonDrive",
  "Proton.ProtonMail",
  "Proton.ProtonPass",
  "Proton.ProtonVPN",
  "qBittorrent.qBittorrent",
  "REALiX.HWiNFO",
  "rcmaehl.MSEdgeRedirect",
  "Symless.Synergy",
  "TheBrowserCompany.Arc",
  "Unity.UnityHub",
  "Valve.Steam",
  "VideoLAN.VLC",
  "winaero.tweaker",
  "Zen-Team.Zen-Brows"
  # Add more packages here
)
foreach ($packageID in $wingetPackageIds) {
  Write-Log "Installing $packageID... " -Type Info -NoNewLine
  $isInstalled = winget list --id $packageID | Select-String -Pattern $packageID
  if ($isInstalled) {
    Write-Log "Skipped (already installed)" -Type Warning
    continue
  }
  try {
    Invoke-Silently { winget install --id $packageID --exact --accept-source-agreements --accept-package-agreements }
    Write-Log "Success" -Type Success
  }
  catch {
    Write-Log "Failed" -Type Error
  }
}

try {
  Write-Log "Cleaning up .lnk files from desktop directories... " -Type Info -NoNewLine
  $desktopDirectoryPaths = @(
    [Environment]::GetFolderPath('Desktop'),
    [Environment]::GetFolderPath('CommonDesktopDirectory')
  )
  foreach ($desktopDirectoryPath in $desktopDirectoryPaths) {
    if (-not (Test-Path $desktopDirectoryPath)) { return }
    Get-ChildItem -Path $desktopDirectoryPath -Filter "*.lnk" -Force | Remove-Item -Force
  }
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Resetting environment variable 'PATH'... " -Type Info -NoNewLine
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machinePath;$userPath"
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Adding settings to global 'Git' config... " -Type Info -NoNewLine
  # Automatically set up remote tracking branches when pushing for the first time
  git config --global push.autoSetupRemote true
  # Set the default branch name to 'main' when initializing a new repository
  git config --global init.defaultBranch main
  # Use the credential cache to store credentials temporarily for faster authentication
  git config --global credential.helper cache
  # Enable rebase when pulling changes, keeping a linear commit history
  git config --global pull.rebase true
  # Set Visual Studio Code as the default editor for Git, opening in a new window and waiting for edits to complete
  git config --global core.editor "code --new-window --wait"
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Downloading personal 'Winaero Tweaker' settings export file... " -Type Info -NoNewLine
  Invoke-WebRequest `
    -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/winaero-tweaker-export.ini" `
    -OutFile "$env:USERPROFILE\Desktop\winaero-tweaker-export.ini"
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Downloading personal 'WinUtil' settings export file... " -Type Info -NoNewLine
  $tempWinUtilExportPath = Join-Path $env:TEMP "winutil-export.json"
  Invoke-WebRequest `
    -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/winutil-export.json" `
    -OutFile $tempWinUtilExportPath
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

try {
  Write-Log "Running 'WinUtil' with my settings... " -Type Info -NoNewLine

  $scriptBlock = {
    Invoke-Expression "& { $(Invoke-RestMethod christitus.com/win) } -Config $tempWinUtilExportPath -Run"
    Exit
  }

  $processParams = @{
    FilePath     = "powershell.exe"
    Wait         = $true
    ArgumentList = @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-Command", "& { $scriptBlock }"
    )
  }

  Start-Process @processParams
  Write-Log "Success" -Type Success
}
catch {
  Write-Log "Failed" -Type Error
}

Write-Log "Setup complete!" -Type Success
