
# Prompt the user to answer a yes or no question.
# Arguments:
#   question: The question to ask the user.
# Returns:
#   True if the user answers yes, otherwise false.
function Get-Answer {
  param (
    [Parameter(Mandatory = $true)]
    [string]$question
  )

  do {
    $response = Read-Host -Prompt "$question (Y/N)"
  } while ($response -notin @('y', 'Y', 'yes', 'Yes', 'n', 'N', 'no', 'No'))

  return $response -in @('y', 'Y', 'yes', 'Yes')
}

function Start-AsAdmin {
  param([ScriptBlock]$ScriptBlock)
  Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$ScriptBlock`"" -Verb RunAs
}

# The main function.
function Main {
  $scoopApps = @{
    'extras'     = @(
      'bitwarden',
      'bruno', 
      'discord',
      'hibit-uninstaller',
      'imageglass',
      'notion',
      'obs-studio',
      'powertoys',
      'qbittorrent',
      'vlc',
      'winaero-tweaker'
    )
    'games'      = @(
      'epic-games-launcher',
      'steam'
    )
    'main'       = @(
      '7zip',
      'bun',
      'docker',
      'git',
      'neovim',
      'nodejs',
      'oh-my-posh',
      'python',
      'terminal-icons'
    )
    'nerd-fonts' = @(
      'JetBrains-Mono'
    )
    'versions'   = @(
      'brave-beta',
      'vscode-insiders'
    )
  }

  # Install Scoop if it is not already installed.
  if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  } 
  
  # Install Git first because Scoop requires it for adding buckets.
  scoop install git
  
  # Loop through each bucket and install the apps.
  foreach ($bucket in $scoopApps.Keys) {
    scoop bucket add $bucket
    foreach ($app in $scoopApps[$bucket]) {
      scoop install "$bucket/$app"
    }
  }

  Start-AsAdmin -ScriptBlock {
  }
}

# Entry point.
Main

# Apps that need to be installed manually:
# - Synergy
# - Proton Mail
# - Proton Drive
# - Proton Pass
# - Proton VPN
# - Powershell 7
# - Visual Studio 2022 Community + Visual Studio Installer
# - WinUtil (Command: "irm https://christitus.com/win | iex")
