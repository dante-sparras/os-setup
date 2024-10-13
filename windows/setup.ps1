#!/usr/bin/env pwsh

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
function Install-WingetPackage {
  param (
    [string]$id,
    [bool]$asAdmin = $true
  )

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
function Install-ChocoPackage {
  param(
    [string]$name,
    [bool]$asAdmin = $true
  )

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

# Exit if not running as admin.
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  Write-Host "This script must be run as an administrator."
  exit 0;
}

#region Software
# Install Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
else {
  Write-Host "Choco is already installed."
}

# Install Choco Packages
Install-ChocoPackage -name "firacode"
Install-ChocoPackage -name "firacodenf"
Install-ChocoPackage -name "inter"

# Install Winget Packages
# General
Install-WingetPackage -id "Discord.Discord"
Install-WingetPackage -id "EpicGames.EpicGamesLauncher" -asAdmin $false
Install-WingetPackage -id "Notion.Notion"
Install-WingetPackage -id "Proton.ProtonDrive"
Install-WingetPackage -id "Proton.ProtonMail"
Install-WingetPackage -id "Proton.ProtonPass"
Install-WingetPackage -id "Proton.ProtonVPN"
Install-WingetPackage -id "Spotify.Spotify" -asAdmin $false
Install-WingetPackage -id "TheBrowserCompany.Arc"
Install-WingetPackage -id "Valve.Steam"
Install-WingetPackage -id "Zen-Team.Zen-Browser"
# Development
Install-WingetPackage -id "BlenderFoundation.Blender"
Install-WingetPackage -id "Docker.DockerDesktop"
Install-WingetPackage -id "Figma.Figma"
Install-WingetPackage -id "Git.Git"
Install-WingetPackage -id "GitHub.cli"
Install-WingetPackage -id "GitHub.GitHubDesktop"
Install-WingetPackage -id "JanDeDobbeleer.OhMyPosh"
Install-WingetPackage -id "JetBrains.Rider"
Install-WingetPackage -id "Microsoft.PowerShell"
Install-WingetPackage -id "Microsoft.VisualStudio.2022.Community"
Install-WingetPackage -id "Microsoft.VisualStudioCode"
Install-WingetPackage -id "Unity.UnityHub"
# Programming Languages, Runtimes, Frameworks
Install-WingetPackage -id "DenoLand.Deno"
Install-WingetPackage -id "Microsoft.DotNet.SDK.8"
Install-WingetPackage -id "OpenJS.NodeJS"
Install-WingetPackage -id "Oven-sh.Bun"
# Utilities & Tools
Install-WingetPackage -id "7zip.7zip"
Install-WingetPackage -id "AntibodySoftware.WizFile"
Install-WingetPackage -id "AntibodySoftware.WizTree"
Install-WingetPackage -id "AsaphaHalifa.AudioRelay"
Install-WingetPackage -id "DuongDieuPhap.ImageGlass"
Install-WingetPackage -id "HiBitSoftware.HiBitUninstaller"
Install-WingetPackage -id "Logitech.GHUB"
Install-WingetPackage -id "Microsoft.PowerToys"
Install-WingetPackage -id "Microsoft.WindowsADK"
Install-WingetPackage -id "qBittorrent.qBittorrent"
Install-WingetPackage -id "Symless.Synergy"
Install-WingetPackage -id "VideoLAN.VLC"
Install-WingetPackage -id "winaero.tweaker"

# Remove all shortcuts from the Desktop
Remove-Item -Path "C:\Users\*\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue
#endregion

#region Registry
# Toggle on Dark Mode
$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $themePath -Name "AppsUseLightTheme" -Value 0
Set-ItemProperty -Path $themePath -Name "SystemUsesLightTheme" -Value 0

# Set Search in Taskbar to hide
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0

# Toggle off the Task View Button in the Taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

# Show extensions in File Explorer
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
#endregion

Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
