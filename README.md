# My Computer Setup

## Windows

1. Start **Powershell** with the **Run as Administrator** (Win + X, A).
2. Set the **ExecutionPolicy** to **RemoteSigned** to run unsigned scripts that you write on your local computer and signed scripts from other users with the following command:

   ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. Run my script to install my preferred software with the following command:

   ```powershell
    Invoke-RestMethod -Uri "https://raw.githubusercontent.com/dante-sparras/computer-setup/main/windows/windows-setup.ps1" | Invoke-Expression
   ```

- Configure **Git** with your name and private email with the following commands:
  ```powershell
   git config --global user.name "Dante Sparrås"
   git config --global user.email "55974949+dante-sparras@users.noreply.github.com"
  ```

## Linux

## Mac
