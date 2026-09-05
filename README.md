# dotfiles

## インストール方法

### Linux (WSL / Ubuntu Server)

```bash
# clone, apply dotfiles, and run initial setup
curl -fsSL https://raw.githubusercontent.com/njfa/dotfiles/main/bin/de | bash -s -- install
```

```bash
# choose a custom clone path or branch, then apply and bootstrap
curl -fsSL https://raw.githubusercontent.com/njfa/dotfiles/main/bin/de | bash -s -- install --path "$HOME/.dotfiles" --branch main
```

```bash
cd /path/to/dotfiles
./bin/de
./bin/de init
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
bash tests/run.sh
# PowerShellがある環境で、設定の保全と失敗時の終了コードを検証
pwsh -NoProfile -File tests/windows-setup.ps1
```

chezmoiの適用時に `~/.config/dotfiles/bin` からリポジトリ内の `bin` へのリンクを作成します。カスタム配置先でもシェル・tmux・lazygitはこのリンクを使用します。配置先を移動した場合は、新しい場所から `./bin/de init` を実行してください。

Neovimのプラグイン構成は `dot_config/nvim/lazy-lock.json` で管理します。プラグイン更新を確認した後、適用先の `~/.config/nvim/lazy-lock.json` をこのファイルへコピーして差分をコミットしてください。固定された構成への復元はNeovimの `:Lazy restore` で行います。

Java（Mavenマルチモジュール）・Python・GoのLSP構成と環境設定は [NeovimのLSP](docs/neovim-lsp.md) を参照してください。

WindowsのNeovim設定はコピー完了後に置き換え、既存設定は同じ親ディレクトリの `nvim.backup.<ID>` に保持します。セットアップに失敗すると終了コード1を返します。

### Orca Server（個別インストール）

Orca Serverは通常セットアップおよび`optional`タスクには含まれません。事前にTailscaleをインストールしてtailnetへ接続したうえで、個別にインストールします。タスクは`tailscaled.service`の起動状態を確認し、`tailscale ip -4`から広告アドレスを自動設定します。

```bash
./bin/de m run orca-server
```

起動が完了すると、スマートフォン用のペアリングURLとQRコードがターミナルに表示されます。スマートフォンも同じtailnetへ接続し、Orca Mobileで`Pair`を選択して、QRコードを読み取るかペアリングURLを貼り付けます。ペアリングコードは短時間で期限切れになるため、その場合はタスクをもう一度実行して新しいコードを生成します。

既定ではポート`6768`を使用し、実行ユーザーの権限で`orca-serve.service`を起動します。ポートを変える場合は`ORCA_PORT`を指定します。

```bash
ORCA_PORT=16768 ./bin/de m run orca-server
```

Orcaは全ネットワークインターフェースで待ち受けるため、クラウド側のセキュリティグループまたはホスト側のファイアウォールで、ポートへのアクセスをTailscaleインターフェースなどに制限してください。公開インターネットへポートを直接開放しないでください。表示されたペアリングURLは認証情報として扱い、接続するスマートフォン以外とは共有しないでください。

### Windows

```powershell
Invoke-Command -ScriptBlock ([scriptblock]::Create((new-object net.webclient).downloadstring("https://raw.github.com/njfa/dotfiles/main/bin/setup.ps1"))) -ArgumentList "init"
```
