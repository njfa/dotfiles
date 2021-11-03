# dotfiles

## インストール方法

### Windows

```powershell
Invoke-Command -ScriptBlock ([scriptblock]::Create((new-object net.webclient).downloadstring("https://raw.github.com/njfa/dotfiles/main/bin/setup.ps1"))) -ArgumentList "init"
```
