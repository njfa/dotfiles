# dotfiles

## インストール方法

### Linux (WSL / Ubuntu Server)

```bash
curl -fsSL https://raw.githubusercontent.com/njfa/dotfiles/main/bin/de | bash -s -- install
```

```bash
curl -fsSL https://raw.githubusercontent.com/njfa/dotfiles/main/bin/de | bash -s -- install --path "$HOME/.dotfiles" --branch main
```

```bash
cd /path/to/dotfiles
./bin/de
./bin/de m run deploy
./bin/de m run sync-to-windows
```

```bash
# ツールのパススルー実行例
./bin/de m --version
./bin/de c apply --source .
./bin/de a --version
```

### 検証

```bash
# リポジトリ直下で実行
./bin/de
./bin/de m --version
./bin/de a --version
```

### Windows

```powershell
Invoke-Command -ScriptBlock ([scriptblock]::Create((new-object net.webclient).downloadstring("https://raw.github.com/njfa/dotfiles/main/bin/setup.ps1"))) -ArgumentList "init"
```
