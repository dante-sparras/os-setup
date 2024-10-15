# Install Winfetch (if not already installed)
# https://www.powershellgallery.com/packages/winfetch
if (-not (Get-InstalledScript -Name winfetch)) {
    Install-Script -Name winfetch -Scope CurrentUser -Force -AcceptLicense
}
# Install Microsoft WinGet Client (if not already installed)
# https://www.powershellgallery.com/packages/Microsoft.WinGet.Client
if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
    Install-Module -Name Microsoft.WinGet.Client -Scope CurrentUser -Force -SkipPublisherCheck
}

# Initialize Oh-My-Posh
#oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/amro.omp.json | Invoke-Expression

$PSROptions = @{
    ContinuationPrompt = '  '
    Colors             = @{
        Parameter        = $PSStyle.Foreground.Magenta
        Selection        = $PSStyle.Background.Blue
        InLinePrediction = $PSStyle.Foreground.BrightYellow + $PSStyle.Background.BrightBlack
    }
}
Set-PSReadLineOption @PSROptions

#### Utitility Functions ####

# Update all apps (except Unity Editors)
function Update-Apps {
    $unityEditorIDPattern = "^(Unity\.Unity\.).*$"

    Get-WinGetPackage | Where-Object {
        $_.IsUpdateAvailable -and
        $_.Id -notmatch $unityEditorIDPattern
    } | ForEach-Object {
        Update-WinGetPackage -Id $_.Id -Confirm
    }
}
