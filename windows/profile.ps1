# Install Winfetch (if not already installed)
# https://www.powershellgallery.com/packages/winfetch
if (-not (Get-InstalledScript -Name winfetch)) {
    Install-Script -Name winfetch -Force -AcceptLicense
}

#### Utitility Functions ####

# Updates all Winget packages
function Update-All {
    $packagesToExclude = @(
        "^Unity\.Unity\."
        # Add more packages to ignore here
    )

    function Install-WingetPackage {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string[]]$PackagesIds
        )
        $packageResults = @()
        $currentPackageIndex = 0

        foreach ($PackageID in @($PackagesIds)) {
            $currentPackageIndex++
            $percentComplete = ($currentPackageIndex / $PackagesIds.Count) * 100
            $packageAlreadyInstalled = winget list --id $PackageID | Select-String -Pattern $PackageID

            if ($packageAlreadyInstalled) {
                Write-Progress -Activity "Installing Packages" -Status "Skipped $PackageID (already installed)" -PercentComplete $percentComplete
                $packageResults += [PSCustomObject]@{
                    ID     = $PackageID
                    Status = "Skipped"
                }
                continue
            }

            Write-Progress -Activity "Installing Packages" -Status "Installing $PackageID" -PercentComplete $percentComplete
            try {
                winget install --id $PackageID --exact --accept-source-agreements --accept-package-agreements --silent *> $null
                $packageResults += [PSCustomObject]@{
                    ID     = $PackageID
                    Status = "Installed"
                }
                Write-Progress -Activity "Installing Packages" -Status "Installed $PackageID" -PercentComplete $percentComplete
            }
            catch {
                $packageResults += [PSCustomObject]@{
                    ID     = $PackageID
                    Status = "Failed"
                }
                Write-Progress -Activity "Installing Packages" -Status "Failed to install $PackageID" -PercentComplete $percentComplete
            }
        }
        Write-Progress -Activity "Installing Packages" -Completed

        Write-Host "`nInstallation Summary:" -ForegroundColor Cyan
        $packageResults | Format-Table -AutoSize
    }

    $upgradablePackagesIds = winget upgrade | Select-Object -Skip 1 | ForEach-Object {
        if (-not $_ -or $_.StartsWith('-')) { return }

        $parts = $_ -split '\s{2,}'
        $packageID = $parts[1]

        return $packageID
    }

    $upgradablePackagesIds = $upgradablePackagesIds | Where-Object {
        $_ -NotMatch $packagesToExclude
    }

    if ($upgradablePackagesIds.Count -eq 0) {
        Write-Host "All apps are up to date" -ForegroundColor Green
        return
    }

    Install-WingetPackage -PackagesIds $upgradablePackagesIds

    Get-ChildItem -Path "$env:USERPROFILE\Desktop\*.lnk" | Remove-Item -Force
    Write-Host "Shortcuts removed from desktop" -ForegroundColor Green
}
