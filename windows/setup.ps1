#!/usr/bin/env pwsh

#region Functions
# Overwrites the last line with a new output.
function Write-HostOverwrite {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
    [System.Object] $Object,
    [System.ConsoleColor] $ForegroundColor,
    [System.ConsoleColor] $BackgroundColor
  )
  $host.UI.RawUI.CursorPosition = @{
    X = 0
    Y = $host.UI.RawUI.CursorPosition.Y - 1
  }
  Write-Host (" " * $host.UI.RawUI.BufferSize.Width) -NoNewline
  $host.UI.RawUI.CursorPosition = @{
    X = 0
    Y = $host.UI.RawUI.CursorPosition.Y
  }

  $writeHostParams = @{}
  if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
    $writeHostParams['ForegroundColor'] = $ForegroundColor
  }
  if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
    $writeHostParams['BackgroundColor'] = $BackgroundColor
  }
  Write-Host $Object @writeHostParams
}
# Installs one or more packages with Winget.
function Install-WingetPackage {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string[]]$Packages
  )
  $packageManagers = @{
    "Winget" = @{
      CheckCommand   = {
        param($package)
        winget list --id $package | Select-String -Pattern $package
      }
      InstallCommand = {
        param($package)
        winget install --id $package --exact --accept-source-agreements --accept-package-agreements --silent *> $null
      }
    }
  }
  $commands = $packageManagers["Winget"]

  foreach ($Package in @($Packages)) {
    $isInstalled = & $commands.CheckCommand $Package
    if ($isInstalled) {
      Write-Host "Skipped `"$Package`" (already installed)"
      continue
    }

    Write-Host "Installing `"$Package`"..."
    try {
      & $commands.InstallCommand $Package
      Write-HostOverwrite "Installed `"$Package`"" -ForegroundColor Green
    }
    catch {
      Write-HostOverwrite "Failed to install `"$Package`"" -ForegroundColor Red
    }
  }
}
# Downloads the first zip file matching the pattern in the latest release from
# the GitHub repo, extracts the files, and installs the font files.
function Install-FontsFromGitHubRepo {
  param (
    [string]$Repo,
    [string]$Pattern
  )
  $headers = @{
    "User-Agent" = "PowerShell Script"
    "Accept"     = "application/vnd.github.v3+json"
  }
  $githubApiReleaseUrl = "https://api.github.com/repos/$Repo/releases/latest"

  $latestReleaseInfo = Invoke-RestMethod -Uri $githubApiReleaseUrl -Headers $headers
  $fontZipAsset = $latestReleaseInfo.assets | Where-Object { $_.name -like "*$Pattern*.zip" } | Select-Object -First 1
  if (-not $fontZipAsset) {
    Write-Host "No font zip file matching '$Pattern' found in '$Repo'"
    return
  }

  $tempZipPath = Join-Path $env:TEMP $fontZipAsset.name
  Write-Host "Downloading fonts from `"$Repo`"..."
  Invoke-WebRequest -Uri $fontZipAsset.browser_download_url -OutFile $tempZipPath

  $tempExtractPath = Join-Path $env:TEMP "$($fontZipAsset.name)_extracted"
  Write-HostOverwrite "Extracting fonts from `"$Repo`"..."
  Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

  $fontFilesInstalled = 0
  $fontFilesSkipped = 0
  Write-HostOverwrite "Installing fonts from `"$Repo`"..."
  Get-ChildItem -Path $tempExtractPath -Recurse -Include *.ttf, *.otf | ForEach-Object {
    $fontFile = $_
    $fontRegistryName = $fontFile.BaseName
    $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $fontType = if ($fontFile.Extension -eq ".otf") { "OpenType" } else { "TrueType" }
    $fontRegistryEntry = "$fontRegistryName ($fontType)"

    $existingFont = Get-ItemProperty -Path $fontRegistryPath -Name $fontRegistryEntry -ErrorAction SilentlyContinue
    if (-not $existingFont) {
      $fontFilesSkipped++
      continue
    }

    Copy-Item -Path $fontFile.FullName -Destination "$env:WINDIR\Fonts" -ErrorAction SilentlyContinue -Force
    $fontFileName = $fontFile.Name
    New-ItemProperty -Path $fontRegistryPath -Name $fontRegistryEntry -Value $fontFileName -PropertyType String -Force | Out-Null
    $fontFilesInstalled++
  }
  Remove-Item $tempZipPath, $tempExtractPath -Recurse -Force
  Write-HostOverwrite "Successfully installed $($fontFilesInstalled) ($($fontFilesSkipped) skipped) fonts from `"$Repo`" (latest release)" -ForegroundColor Green
}
#endregion

#### Start of the script ####

# Check if PowerShell is running as an administrator
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$admin = [Security.Principal.WindowsBuiltInRole]::Administrator
if (-not ($principal.IsInRole($admin))) {
  Write-Host "Please run PowerShell as an administrator" -ForegroundColor Red
  return
}

# Create a PowerShell profile directory if it doesn't exist
switch ($PSVersionTable.PSEdition) {
  "Core" { $profileDirectoryPath = "$env:USERPROFILE\Documents\Powershell" }
  "Desktop" { $profileDirectoryPath = "$env:USERPROFILE\Documents\WindowsPowerShell" }
}
if (-not (Test-Path -Path $profileDirectoryPath)) {
  Write-Host "Creating PowerShell profile directory ..."
  New-Item -Path $profileDirectoryPath -ItemType Directory | Out-Null
  Write-HostOverwrite "Successfully created PowerShell profile directory" -ForegroundColor Green
}

# Backup current PowerShell profile if it exists
if (Test-Path -Path $PROFILE -PathType Leaf) {
  Write-Host "PowerShell profile found. Moving it to `"$profileDirectoryPath\oldprofile.ps1`"..."
  Move-Item -Path $PROFILE -Destination "$profileDirectoryPath\oldprofile.ps1" -Force
  Write-HostOverwrite "Successfully moved PowerShell profile to `"$profileDirectoryPath\oldprofile.ps1`"" -ForegroundColor Green
}

# Install Chris Titus Tech's PowerShell profile
Write-Host "Installing Chris Titus Tech's PowerShell profile..."
Invoke-RestMethod `
  -Uri "https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1" `
  -OutFile $PROFILE
Write-HostOverwrite "Successfully installed Chris Titus Tech's PowerShell profile" -ForegroundColor Green

# Install my custom PowerShell profile
Write-Host "Installing my custom PowerShell profile..."
Invoke-WebRequest `
  -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/profile.ps1" `
  -OutFile "$profileDirectoryPath\profile.ps1"
Write-HostOverwrite "Successfully installed my custom PowerShell profile" -ForegroundColor Green

# Install Fira Code and Fira Code Nerd Font
Install-FontsFromGitHubRepo -Repo "tonsky/FiraCode" -Pattern "Fira_Code"
Install-FontsFromGitHubRepo -Repo "ryanoasis/nerd-fonts" -Pattern "FiraCode"

# Install Winget packages
$wingetPackagesToInstall = @(
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
  "Microsoft.WSL",
  "Notion.Notion",
  "Notion.NotionCalendar",
  "Nvidia.GeForceExperience",
  "OBSProject.OBSStudio",
  "OpenJS.NodeJS",
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
Install-WingetPackage $wingetPackagesToInstall

# Reset environment path
Write-Host "Resetting environment path..."
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"
Write-HostOverwrite "Environment path reset" -ForegroundColor Green

# Add global Git config settings
Write-Host "Adding global Git config settings..."
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
Write-HostOverwrite "Added global Git config settings" -ForegroundColor Green

# Remove shortcuts from desktop
Write-Host "Removing shortcuts from desktop..."
Get-ChildItem -Path "$env:USERPROFILE\Desktop\*.lnk" | Remove-Item -Force
Write-HostOverwrite "Shortcuts removed from desktop" -ForegroundColor Green

# Download my Winaero Tweaker settings export file to the desktop
Write-Host "Downloading `"winaero-tweaker-export.ini`" to the desktop..."
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/dante-sparras/os-setup/main/windows/winaero-tweaker-export.ini" `
  -OutFile "$env:USERPROFILE\Desktop\winaero-tweaker-export.ini"
Write-HostOverwrite "Downloaded `"winaero-tweaker-export.ini`" to the desktop" -ForegroundColor Green
