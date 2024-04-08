# Enable Terminal Icons
Import-Module -Name Terminal-Icons


# Enable Oh-My-Posh
& ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" --print) -join "`n"))