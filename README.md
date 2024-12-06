# Windows Setup Script

## Run Script

1. Start **Powershell** with the **Run as Administrator** (Win + X, A).
2. Set the **ExecutionPolicy** to **RemoteSigned** with the following command:

   ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. Run the following command to download and execute the `setup.ps1` script:

   ```powershell
    Invoke-RestMethod -Uri "https://github.com/dante-sparras/os-setup/raw/main/windows/setup.ps1" | Invoke-Expression
   ```
