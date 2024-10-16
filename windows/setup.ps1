#!/usr/bin/env pwsh

# Return if not running as admin
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  Write-Host "This script must be run as an administrator."
  return
}

# Create Powershell directory if it doesn't exist
if (!(Test-Path -Path "$env:USERPROFILE\Documents\Powershell")) {
  New-Item -Path "$env:USERPROFILE\Documents\Powershell" -ItemType "directory" | Out-Null
}
# Install Chris Titus Tech's PowerShell profile
# https://github.com/ChrisTitusTech/powershell-profile
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/ChrisTitusTech/powershell-profile/refs/heads/main/Microsoft.PowerShell_profile.ps1" `
  -OutFile "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
# Install PowerShell profile
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/dante-sparras/os-setup/main/windows/profile.ps1" `
  -OutFile "$env:USERPROFILE\Documents\PowerShell\profile.ps1"


# Install fonts
function Install-FontsFromGitHubRepo {
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
    $fontFilesSkipped = 0
    Get-ChildItem -Path $tempExtractPath -Recurse -Include *.ttf, *.otf | ForEach-Object {
      $fontFile = $_
      $fontRegistryName = $fontFile.BaseName
      $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
      $fontType = if ($fontFile.Extension -eq ".otf") { "OpenType" } else { "TrueType" }
      $fontRegistryEntry = "$fontRegistryName ($fontType)"

      $existingFont = Get-ItemProperty `
        -Path $fontRegistryPath `
        -Name $fontRegistryEntry `
        -ErrorAction SilentlyContinue
      if (-not $existingFont) {
        $fontFilesSkipped++
        continue
      }

      Copy-Item `
        -Path $fontFile.FullName `
        -Destination "$env:WINDIR\Fonts" `
        -ErrorAction SilentlyContinue `
        -Force

      $fontFileName = $fontFile.Name
      New-ItemProperty `
        -Path $fontRegistryPath `
        -Name $fontRegistryEntry `
        -Value $fontFileName `
        -PropertyType String -Force `
      | Out-Null

      $fontFilesInstalled++
    }

    Remove-Item $tempZipPath, $tempExtractPath -Recurse -Force

    Write-Host "Installed $($fontFilesInstalled) ($($fontFilesSkipped) skipped) fonts from `"$fontZipAssetName`" downloaded from `"$Repo`" (latest release):"
  }
  catch {
    Remove-Item $tempZipPath, $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Error "Failed to install fonts from '$Repo': $_"
  }
}

Install-FontsFromGitHubRepo -Repo "tonsky/FiraCode" -Pattern "Fira_Code"
Install-FontsFromGitHubRepo -Repo "ryanoasis/nerd-fonts" -Pattern "FiraCode"

# Install winget packages
function Install-WingetPackages {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Packages
  )

  foreach ($package in $Packages) {
    $isInstalled = winget list --id $package | Select-String -Pattern $package
    if ($isInstalled) {
      Write-Output "Skipped `"$package`" (already installed)."
      continue
    }

    Write-Host -NoNewline "Installing `"$package`"..."
    Try {
      winget install --id $package -e --accept-source-agreements --accept-package-agreements -h | Out-Null
      Write-Host "`r$(' ' * 80)" -NoNewline
      Write-Host "`rInstalled `"$package`"" -ForegroundColor Green
    }
    Catch {
      Write-Host "`r$(' ' * 80)" -NoNewline
      Write-Host "`rFailed to install `"$package`"" -ForegroundColor Red
    }
  }
}
$wingetPackages = @(
  "7zip.7zip",
  "AntibodySoftware.WizFile",
  "AntibodySoftware.WizTree",
  "AsaphaHalifa.AudioRelay",
  "BlenderFoundation.Blender",
  "DenoLand.Deno",
  "Discord.Discord",
  "Docker.DockerDesktop",
  "DuongDieuPhap.ImageGlass",
  "EpicGames.EpicGamesLauncher",
  "Git.Git"
  "GitHub.cli",
  "GitHub.GitHubDesktop",
  "Guru3D.Afterburner",
  "JanDeDobbeleer.OhMyPosh",
  "JetBrains.Rider",
  "Logitech.GHUB",
  "Microsoft.DotNet.SDK.8",
  "Microsoft.PowerShell",
  "Microsoft.PowerToys",
  "Microsoft.VisualStudio.2022.Community",
  "Microsoft.VisualStudioCode",
  "Notion.Notion",
  "OpenJS.NodeJS",
  "Oven-sh.Bun",
  "Proton.ProtonDrive",
  "Proton.ProtonMail",
  "Proton.ProtonPass",
  "Proton.ProtonVPN",
  "qBittorrent.qBittorrent",
  "Symless.Synergy",
  "TheBrowserCompany.Arc",
  "Unity.UnityHub",
  "Valve.Steam",
  "VideoLAN.VLC",
  "winaero.tweaker",
  "Zen-Team.Zen-Brows"
)
Install-WingetPackages -Packages $wingetPackages

# Restart environment path, so that package commands will work without restarting Terminal.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Git global configuration
git config --global push.autoSetupRemote true
git config --global init.defaultBranch main
git config --global credential.helper cache
git config --global pull.rebase true
git config --global core.editor "code --new-window --wait"
git config --global diff.tool default-difftool
git config --global merge.tool code
git config --global difftool.default-difftool.cmd "code --new-window --wait --diff `$LOCAL `$REMOTE"
git config --global mergetool.code.cmd "code --new-window --wait --merge `$REMOTE `$LOCAL `$BASE `$MERGED"

# Remove all shortcuts from desktop
Get-ChildItem -Path "$env:USERPROFILE\Desktop\*.lnk" | Remove-Item -Force

# Download "winaero-tweaker-export.ini" to the desktop
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/dante-sparras/os-setup/main/windows/winaero-tweaker-export.ini" `
  -OutFile "$env:USERPROFILE\Desktop\winaero-tweaker-export.ini"

# Run Chris Titus Tech's Windows Utility
Invoke-RestMethod "https://christitus.com/win" | Invoke-Expression
