#!/usr/bin/env pwsh

#region Functions
function Install-WingetPackage {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string[]]$PackagesIds
  )
  $currentPackageIndex = 0

  foreach ($PackageID in @($PackagesIds)) {
    $currentPackageIndex++
    $percentComplete = ($currentPackageIndex / $PackagesIds.Count) * 100
    $packageAlreadyInstalled = winget list --id $PackageID | Select-String -Pattern $PackageID

    if ($packageAlreadyInstalled) {
      Write-Host "Skipping $PackageID (already installed)" -ForegroundColor Yellow
      continue
    }

    Write-Progress -Activity "Installing Packages" -Status "Installing $PackageID..." -PercentComplete $percentComplete
    try {
      winget install --id $PackageID --exact --accept-source-agreements --accept-package-agreements --silent *> $null
      Write-Progress -Activity "Installing Packages" -Status "Installed $PackageID" -PercentComplete $percentComplete
      Write-Host "Successfully installed $PackageID" -ForegroundColor Green
    }
    catch {
      Write-Progress -Activity "Installing Packages" -Status "Failed to install $PackageID" -PercentComplete $percentComplete
      Write-Host "Failed to install $PackageID" -ForegroundColor Red
    }
  }
}
function Invoke-GitHubApiRequest {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$Endpoint
  )
  $headers = @{
    "User-Agent" = "PowerShell Script"
    "Accept"     = "application/vnd.github+json"
  }

  try {
    return Invoke-WebRequest -Uri "https://api.github.com/$Endpoint" -Headers $headers | ConvertFrom-Json
  }
  catch {
    Write-Error "Error: $_"
  }

}
function Install-FontsFromZipUrl {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$ZipUrl
  )

  Add-Type -AssemblyName System.Drawing

  function Get-FontFamilyName {
    param(
      [string]$FontPath
    )

    $fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
    $fontCollection.AddFontFile($FontPath)
    $familyName = $fontCollection.Families[0].Name
    $fontCollection.Dispose()
    return $familyName
  }

  function Install-Font {
    param(
      [string]$Path
    )

    $fontPath = Resolve-Path $Path -ErrorAction Stop
    $fontFileName = [System.IO.Path]::GetFileName($fontPath)
    $fontFamilyName = Get-FontFamilyName -FontPath $fontPath
    $installedFonts = @(Get-ChildItem -Path "C:\Windows\Fonts" -Name)

    if ($installedFonts -contains $fontFileName) {
      Write-Host "Font '$fontFamilyName' is already installed." -ForegroundColor Yellow
      return
    }

    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14)
    $fontsFolder.CopyHere($fontPath, 0x14)
    Write-Host "Font '$fontFamilyName' installed successfully." -ForegroundColor Green
  }

  $tempZipDirPath = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
  $tempZipFilePath = Join-Path $tempZipDirPath "font.zip"
  $tempExtractDirPath = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
  try {
    New-Item -ItemType Directory -Path $tempZipDirPath | Out-Null
    New-Item -ItemType Directory -Path $tempExtractDirPath | Out-Null

    Invoke-WebRequest -Uri $ZipUrl -OutFile $tempZipFilePath
    Expand-Archive -Path $tempZipFilePath -DestinationPath $tempExtractDirPath -Force

    $fontFiles = Get-ChildItem -Path $tempExtractDirPath -Recurse -File -Include *.ttf, *.otf
    foreach ($fontFile in $fontFiles) {
      Install-Font -Path $fontFile
    }
  }
  catch {
    Write-Error "$_"
  }
  finally {
    if (Test-Path $tempZipDirPath) { Remove-Item -Path $tempZipDirPath -Recurse -Force }
    if (Test-Path $tempExtractDirPath) { Remove-Item -Path $tempExtractDirPath -Recurse -Force }
  }
}
#endregion

########################################################################################################################
##                                                                                                                    ##
##                                                    Admin Check                                                     ##
##                                                                                                                    ##
########################################################################################################################

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
if (-not ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  Write-Host "Please run PowerShell as an administrator" -ForegroundColor Red
  return
}

########################################################################################################################
##                                                                                                                    ##
##                                            Install PowerShell Profiles                                             ##
##                                                                                                                    ##
########################################################################################################################

# Determine PowerShell profile directory path
switch ($PSVersionTable.PSEdition) {
  "Core" { $profileDirectoryPath = "$env:USERPROFILE\Documents\Powershell" }
  "Desktop" { $profileDirectoryPath = "$env:USERPROFILE\Documents\WindowsPowerShell" }
}

# Backup old PowerShell profile
if (Test-Path -Path $PROFILE -PathType Leaf) {
  Move-Item -Path $PROFILE -Destination "$profileDirectoryPath\oldprofile.ps1" -Force
  Write-Host "Successfully moved PowerShell profile to `"$profileDirectoryPath\oldprofile.ps1`"" -ForegroundColor Green
}

# Create PowerShell profile directory if it doesn't exist
if (-not (Test-Path -Path $profileDirectoryPath)) {
  New-Item -Path $profileDirectoryPath -ItemType Directory | Out-Null
  Write-Host "Successfully created PowerShell profile directory" -ForegroundColor Green
}

# Install Chris Titus Tech's PowerShell profile
Invoke-RestMethod `
  -Uri "https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1" `
  -OutFile $PROFILE
Write-Host "Successfully installed Chris Titus Tech's PowerShell profile" -ForegroundColor Green

# Install personal PowerShell profile
Invoke-WebRequest `
  -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/profile.ps1" `
  -OutFile "$profileDirectoryPath\profile.ps1"
Write-Host "Successfully installed my custom PowerShell profile" -ForegroundColor Green

########################################################################################################################
##                                                                                                                    ##
##                                                   Install Fonts                                                    ##
##                                                                                                                    ##
########################################################################################################################

# Install Chocolatey
Write-Progress -Activity "Installing Chocolatey" -Status "Installing Chocolatey..." -PercentComplete 0
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) *> $null
Write-Progress -Activity "Installing Packages" -Status "Installed Chocolatey" -PercentComplete 100
Write-Host "Successfully installed Chocolatey" -ForegroundColor Green

# Install Fonts
Write-Progress -Activity "Installing Fonts" -Status "Installing Fonts..." -PercentComplete 0
choco install --confirm --limitoutput firacode *> $null
choco install --confirm --limitoutput firacodenf *> $null
Write-Progress -Activity "Installing Fonts" -Status "Installed Fonts" -PercentComplete 100
Write-Host "Successfully installed fonts" -ForegroundColor Green

########################################################################################################################
##                                                                                                                    ##
##                                              Install Winget Packages                                               ##
##                                                                                                                    ##
########################################################################################################################

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
Install-WingetPackage $wingetPackagesToInstall

# Clean up shortcuts from desktop created by installed Winget packages
Get-ChildItem -Path "$env:USERPROFILE\Desktop\*.lnk" | Remove-Item -Force
Write-Host "Shortcuts removed from desktop" -ForegroundColor Green

# Reset environment variable PATH
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

########################################################################################################################
##                                                                                                                    ##
##                                                Git Config (Global)                                                 ##
##                                                                                                                    ##
########################################################################################################################

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
Write-Host "Added global Git config settings" -ForegroundColor Green

########################################################################################################################
##                                                                                                                    ##
##                                                       Other                                                        ##
##                                                                                                                    ##
########################################################################################################################

# Download my Winaero Tweaker settings export file to the desktop
Invoke-WebRequest `
  -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/winaero-tweaker-export.ini" `
  -OutFile "$env:USERPROFILE\Desktop\winaero-tweaker-export.ini"
Write-Host "Downloaded `"winaero-tweaker-export.ini`" to the desktop" -ForegroundColor Green

########################################################################################################################
##                                                                                                                    ##
##                                                   WinUtil Tweaks                                                   ##
##                                                                                                                    ##
########################################################################################################################

# Download my WinUtil config
$tempWinUtilExportPath = Join-Path $env:TEMP "winutil-export.json"
Invoke-WebRequest `
  -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/winutil-export.json" `
  -OutFile $tempWinUtilExportPath
# Run WinUtil with my config in a new PowerShell window
Start-Process powershell -Wait -ArgumentList "-Command `"& { $(Invoke-RestMethod christitus.com/win) } -Config $tempWinUtilExportPath -Run`""
Write-Host "Completed all WinUtil tweaks" -ForegroundColor Green
