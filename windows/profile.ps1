# Install Winfetch (if not already installed)
# https://www.powershellgallery.com/packages/winfetch
if (-not (Get-InstalledScript -Name winfetch)) {
    Install-Script -Name winfetch -Force -AcceptLicense
}

# Initialize Oh-My-Posh
oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/amro.omp.json | Invoke-Expression

#### Utitility Functions ####

# Updates all Winget packages
function Update-All {
    $toSkip = @(
        "Unity.UnityHub"
        # Add more packages to ignore here
    )

    # Overwrites the last line with a new output
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

    class WingetPackageData {
        [string]$Name
        [string]$ID
        [string]$Version
        [string]$AvailableVersion
    }

    $upgradableWingetPackages = winget upgrade | Select-Object -Skip 1 | ForEach-Object {
        if ($_ -and -not $_.StartsWith('-')) {
            $parts = $_ -split '\s{2,}'

            if ($toSkip -contains $parts[1]) { continue }

            [WingetPackageData]@{
                Name             = $parts[0]
                ID               = $parts[1]
                Version          = $parts[2]
                AvailableVersion = $parts[3]
            }
        }
    }

    if ($upgradableWingetPackages.Count -eq 0) {
        Write-Host "All apps are up to date" -ForegroundColor Green
        return
    }

    $upgradableWingetPackages | ForEach-Object {
        $packageID = $_.ID
        $packageName = $_.Name

        Write-Host "Installing `"$packageName`"..."
        Try {
            winget install --id $packageID --exact --silent --accept-source-agreements --accept-package-agreements *> $null
            Write-HostOverwrite "Installed `"$packageName`"" -ForegroundColor Green
        }
        Catch {
            Write-HostOverwrite "Failed to install `"$packageName`"" -ForegroundColor Red
        }
    }
}
