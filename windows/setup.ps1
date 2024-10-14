#!/usr/bin/env pwsh

# Downloads the first zip file matching the given pattern from the latest
# release of the given repo, extracts it, and installs the .ttf and .otf
# font files.
function Install-FontFromGitHubRelease {
  param (
    # Repo name in the format "owner/repo"
    [string]$Repo,
    # Pattern for the zip file name in the latest release
    [string]$Pattern
  )
  $headers = @{
    "User-Agent" = "PowerShell Script"
    "Accept"     = "application/vnd.github.v3+json"
  }
  $githubApiReleaseUrl = "https://api.github.com/repos/$Repo/releases/latest"

  try {
    $latestReleaseInfo = Invoke-RestMethod -Uri $githubApiReleaseUrl -Headers $headers
    $fontZipAsset = $latestReleaseInfo.assets | Where-Object { $_.name -like "*$Pattern*.zip" } | Select-Object -First 1
    $fontZipAssetName = $fontZipAsset.name

    if (-not $fontZipAsset) { throw "No font zip file matching '$Pattern' found in '$Repo'." }

    $tempZipPath = Join-Path $env:TEMP $fontZipAsset.name
    Invoke-WebRequest -Uri $fontZipAsset.browser_download_url -OutFile $tempZipPath

    $tempExtractPath = Join-Path $env:TEMP "$($fontZipAsset.name)_extracted"
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

    $fontFilesInstalled = 0
    Get-ChildItem -Path $tempExtractPath -Recurse -Include *.ttf, *.otf | ForEach-Object {
      $fontFile = $_
      $fontFileName = $fontFile.Name

      Copy-Item $fontFile.FullName -Destination "$env:WINDIR\Fonts" -Force -ErrorAction SilentlyContinue

      $fontRegistryName = $fontFile.BaseName
      New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
        -Name "$fontRegistryName (TrueType)" `
        -Value $fontFileName `
        -PropertyType String -Force | Out-Null

      $fontFilesInstalled++
    }

    Remove-Item $tempZipPath, $tempExtractPath -Recurse -Force
    Write-Host "Installed $($fontFilesInstalled) fonts from `"$fontZipAssetName`" downloaded from `"$Repo`" (latest release):"
  }
  catch {
    Remove-Item $tempZipPath, $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Error "Failed to install fonts from '$Repo': $_"
  }
}

# Return if not running as admin
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  Write-Host "This script must be run as an administrator."
  return
}

# Install fonts
Install-FontFromGitHubRelease -Repo "tonsky/FiraCode" -Pattern "Fira_Code"
Install-FontFromGitHubRelease -Repo "ryanoasis/nerd-fonts" -Pattern "FiraCode"

# Install apps
winget install --silent --accept-package-agreements --accept-source-agreements `
  7zip.7zip `
  AntibodySoftware.WizFile `
  AntibodySoftware.WizTree `
  AsaphaHalifa.AudioRelay `
  BlenderFoundation.Blender `
  DenoLand.Deno `
  Discord.Discord `
  Docker.DockerDesktop `
  DuongDieuPhap.ImageGlass `
  EpicGames.EpicGamesLauncher `
  Git.Git `
  GitHub.cli `
  GitHub.GitHubDesktop `
  HiBitSoftware.HiBitUninstaller `
  JanDeDobbeleer.OhMyPosh `
  JetBrains.Rider `
  Logitech.GHUB `
  Microsoft.DotNet.SDK.8 `
  Microsoft.PowerShell `
  Microsoft.PowerToys `
  Microsoft.VisualStudio.2022.Community `
  Microsoft.VisualStudioCode `
  Notion.Notion `
  OpenJS.NodeJS `
  Oven-sh.Bun `
  Proton.ProtonDrive `
  Proton.ProtonMail `
  Proton.ProtonPass `
  Proton.ProtonVPN `
  qBittorrent.qBittorrent `
  Symless.Synergy `
  TheBrowserCompany.Arc `
  Unity.UnityHub `
  Valve.Steam `
  VideoLAN.VLC `
  winaero.tweaker `
  Zen-Team.Zen-Browser

# Remove all shortcuts from desktop
Get-ChildItem -Path "$env:USERPROFILE\Desktop\*.lnk" | Remove-Item -Force

# Run Chris Titus Tech's Windows Utility
Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
