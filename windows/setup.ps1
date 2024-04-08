
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

# Finds a command by name.
function Find-Command {
  param([string]$command)
 
  return Get-Command $command -ErrorAction SilentlyContinue
}


# Add a Scoop bucket if it's not already in the bucket list.
function Add-ScoopBucket {
  param([string]$bucket)
  if (!(scoop bucket list | Select-String -SimpleMatch $bucket)) {
    scoop bucket add $bucket
  }
}

# Installs a Scoop app if it's not already installed.
function Install-ScoopApp {
  param([string]$app)
  if (!(scoop list | Out-Null | Select-String -SimpleMatch $app)) {
    scoop install $app
  }
}

# Installs Scoop if it's not already installed.
function Install-Scoop {
  if (!(Find-Command scoop)) {
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  }
  # Git is required for Scoop to be able to add buckets to the bucket list.
  Install-ScoopApp 'git'
}

# The main function.
function Main {
  # --- Scoop ---
  $scoopBucketsAndApps = @{
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
  Install-Scoop
  foreach ($bucket in $scoopBucketsAndApps.Keys) {
    Add-ScoopBucket $bucket
    foreach ($app in $scoopBucketsAndApps[$bucket]) {
      Install-ScoopApp $app
    }
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
