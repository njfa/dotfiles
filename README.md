# dotfiles

## インストール方法

### Linux (WSL / Ubuntu Server)

```bash
cd /path/to/dotfiles
./bin/setup.sh init
```

### 検証 (コンテナ)

```bash
# リポジトリ直下で実行
docker compose run --rm claude-code bash -lc "cd /workspace && ./bin/setup.sh init"
```

```bash
# 主要ツールの動作確認例
docker compose run --rm claude-code bash -lc "cd /workspace && mise --version && node --version && python --version && go version && terraform -version && nvim --version"
```

### Windows

```powershell
Invoke-Command -ScriptBlock ([scriptblock]::Create((new-object net.webclient).downloadstring("https://raw.github.com/njfa/dotfiles/main/bin/setup.ps1"))) -ArgumentList "init"
```
