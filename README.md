# dotfiles

## インストール方法

### Linux (WSL / Ubuntu Server)

```bash
curl -fsSL https://raw.githubusercontent.com/njfa/dotfiles/main/bin/devenv | bash -s -- install
```

```bash
curl -fsSL https://raw.githubusercontent.com/njfa/dotfiles/main/bin/devenv | bash -s -- install --path "$HOME/.dotfiles" --branch main
```

```bash
cd /path/to/dotfiles
./bin/devenv
./bin/devenv mise run deploy
./bin/devenv mise run sync-to-windows
```

```bash
# ツールのパススルー実行例
./bin/devenv mise --version
./bin/devenv chezmoi apply --source .
./bin/devenv apm --version
```

### 検証

```bash
# リポジトリ直下で実行
./bin/devenv
./bin/devenv mise --version
./bin/devenv apm --version
```

### Windows

```powershell
Invoke-Command -ScriptBlock ([scriptblock]::Create((new-object net.webclient).downloadstring("https://raw.github.com/njfa/dotfiles/main/bin/setup.ps1"))) -ArgumentList "init"
```
