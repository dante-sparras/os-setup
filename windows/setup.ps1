#!/usr/bin/env pwsh

# Check if running as administrator
function IsAdmin {
  $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Starts a Powershell process and runs a command.
function Start-PowershellAndRunCommand {
  param(
    [ScriptBlock]$ScriptBlock,
    [bool]$AsAdmin = $false
  )

  if ($AsAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$ScriptBlock`"" -Verb RunAs
    return
  }

  Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$ScriptBlock`""
}

# Installs a Winget app if it's not already installed.
function Install-WingetApp {
  param (
    [string]$id,
    [bool]$asAdmin = $true
  )

  winget list -q $id | Out-Null
  if ($?) {
    Write-Host "$id is already installed."
    return
  }

  try {
    if ($asAdmin) {
      winget install --id=$id --silent --accept-package-agreements --accept-source-agreements
    }

    Start-PowershellAndRunCommand -ScriptBlock {
      winget install --id=$id --silent --accept-package-agreements --accept-source-agreements
    }
  }
  catch {
    Write-Error "Failed to install $id. $_"
  }
}

# Installs a Choco app if it's not already installed.
function Install-ChocoApp {
  param(
    [string]$name,
    [bool]$asAdmin = $true
  )

  if (choco list --local-only | Select-String -Pattern "^$name\s") {
    Write-Host "$name is already installed."
    return
  }

  try {
    if ($asAdmin) {
      choco install $name -y
      return
    }

    Start-PowershellAndRunCommand -ScriptBlock {
      choco install $name -y
    }
  }
  catch {
    Write-Error "Failed to install $name. $_"
  }
}

# Installs Choco if it's not already installed.
function Install-Choco {
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Choco is already installed."
    return
  }

  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

if (-not (IsAdmin)) {
  Write-Host "This script must be run as an administrator."
  return
}

Install-Choco

#### Install Packages ####
# General
Install-WingetApp -id "Discord.Discord"
Install-WingetApp -id "EpicGames.EpicGamesLauncher" -asAdmin $false
Install-WingetApp -id "Notion.Notion"
Install-WingetApp -id "Proton.ProtonDrive"
Install-WingetApp -id "Proton.ProtonMail"
Install-WingetApp -id "Proton.ProtonPass"
Install-WingetApp -id "Proton.ProtonVPN"
Install-WingetApp -id "Spotify.Spotify" -asAdmin $false
Install-WingetApp -id "TheBrowserCompany.Arc"
Install-WingetApp -id "Valve.Steam"
Install-WingetApp -id "Zen-Team.Zen-Browser"
# Development
Install-WingetApp -id "BlenderFoundation.Blender"
Install-WingetApp -id "Docker.DockerDesktop"
Install-WingetApp -id "Figma.Figma"
Install-WingetApp -id "Git.Git"
Install-WingetApp -id "GitHub.cli"
Install-WingetApp -id "GitHub.GitHubDesktop"
Install-WingetApp -id "JanDeDobbeleer.OhMyPosh"
Install-WingetApp -id "JetBrains.Rider"
Install-WingetApp -id "Microsoft.PowerShell"
Install-WingetApp -id "Microsoft.VisualStudio.2022.Community"
Install-WingetApp -id "Microsoft.VisualStudioCode"
Install-WingetApp -id "Unity.UnityHub"
# Programming Languages, Runtimes, Frameworks
Install-WingetApp -id "DenoLand.Deno"
Install-WingetApp -id "Microsoft.DotNet.SDK.8"
Install-WingetApp -id "OpenJS.NodeJS"
Install-WingetApp -id "Oven-sh.Bun"
# Utilities & Tools
Install-WingetApp -id "7zip.7zip"
Install-WingetApp -id "AntibodySoftware.WizFile"
Install-WingetApp -id "AntibodySoftware.WizTree"
Install-WingetApp -id "AsaphaHalifa.AudioRelay"
Install-WingetApp -id "DuongDieuPhap.ImageGlass"
Install-WingetApp -id "HiBitSoftware.HiBitUninstaller"
Install-WingetApp -id "Logitech.GHUB"
Install-WingetApp -id "Microsoft.PowerToys"
Install-WingetApp -id "Microsoft.WindowsADK"
Install-WingetApp -id "qBittorrent.qBittorrent"
Install-WingetApp -id "Symless.Synergy"
Install-WingetApp -id "VideoLAN.VLC"
Install-WingetApp -id "winaero.tweaker"
# Fonts
Install-ChocoApp -name "firacode"
Install-ChocoApp -name "firacodenf"
Install-ChocoApp -name "inter"

$updatePackagesScript = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/dante-sparras/os-setup/main/windows/update-packages.ps1"
$updatePackagesScriptPath = "$env:USERPROFILE\Documents\Powershell\update-packages.ps1"
$updatePackagesShortcutPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\update-packages.lnk"

# Create update packages script and add script content to it
New-Item -Path $updatePackagesScriptPath -ItemType "File" -Force
Add-Content -Path $updatePackagesScriptPath -Value $updatePackagesScript

# Create shortcut in startup folder
$wshell = New-Object -ComObject WScript.Shell
$shortcut = $wshell.CreateShortcut($updatePackagesShortcutPath)

# Make the shortcut run the update packages script with Powershell
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$updatePackagesScriptPath`""
$shortcut.IconLocation = "powershell.exe"

$shortcut.Save()

#### Windows Settings ####

# Remove all shortcuts from the Desktop
Remove-Item -Path "C:\Users\*\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue

# Toggle on Dark Mode
$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $themePath -Name "AppsUseLightTheme" -Value 0
Set-ItemProperty -Path $themePath -Name "SystemUsesLightTheme" -Value 0

# Set Search in Taskbar to hide
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

# Toggle off the Task View Button in the Taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

# Turn on "Settings" to Personalization > Start > Folders

# Show extensions in File Explorer
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# Restart Windows Explorer to apply changes
Stop-Process -Name explorer -Force

#### Run Chris Titus Tech's Windows Utility ####
Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
