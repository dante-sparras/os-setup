# If not running as admin, restart as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$env:USERPROFILE\Documents\Powershell\update-packages.ps1"" " -Verb RunAs
    exit
}

# Update all Winget apps
winget upgrade --all
# Update Chocolatey
choco upgrade chocolatey -y
# Update all Chocolatey apps
choco upgrade all -y
