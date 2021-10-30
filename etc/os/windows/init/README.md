# 初期設定

## WSLのインストール方法

### Windows 10 バージョン 2004 以降 or Windows 11

```powershell
wsl --install
```

### 以前のバージョン

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
