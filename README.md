# My OS Setup

- Login to your [Bitwarden Web Vault](https://vault.bitwarden.com/#/login) and copy the **API Key** from your **GitHub Login**.
- Configure **Git** with your name and private email with the following commands:
  ```powershell
   git config --global user.name "Dante Sparrås"
   git config --global user.email "55974949+dante-sparras@users.noreply.github.com"
  ```

## Windows

1. Start **Powershell** with the **Run as Administrator** (Win + X, A).
2. Set the **ExecutionPolicy** to **RemoteSigned** with the following command:

   ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. Run the following command to download and execute the `setup.ps1` script:

   ```powershell
    Invoke-RestMethod -Uri "https://raw.githubusercontent.com/dante-sparras/os-setup/main/windows/setup.ps1" | Invoke-Expression
   ```

   This will install the following:

   - 7zip
   - bitwarden
   - brave-beta
   - bruno
   - bun
   - discord
   - docker
   - epic-games-launcher
   - git
   - hibit-uninstaller
   - imageglass
   - JetBrains-Mono
   - neovim
   - nodejs
   - notion
   - obs-studio
   - oh-my-posh
   - powertoys
   - python
   - qbittorrent
   - steam
   - terminal-icons
   - vlc
   - vscode-insiders
   - winaero-tweaker
