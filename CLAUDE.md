# CLAUDE.md

このファイルはこのリポジトリのコード作業時にClaude Code（claude.ai/code）にガイダンスを提供します。

## リポジトリ概要

これは様々な開発環境向けの設定ファイルとセットアップスクリプトを提供するdotfilesリポジトリです。異なるツールや開発環境向けのモジュール式初期化スクリプトによるクロスプラットフォーム（Linux/UbuntuとWindows）のセットアップをサポートしています。

## 主要コンポーネント

- **Dotfiles管理**: zsh、neovim、tmuxなどのツール用設定ファイル
- **環境セットアップ**: 異なるUbuntuバージョン向けのOS固有初期化スクリプト
- **コンテナサポート**: Claude AIやその他ツールをコンテナで実行するためのDocker Compose設定
- **カスタムユーティリティ**: 様々な開発タスク用シェルスクリプト

## コンテナ化されたClaude環境

このリポジトリにはClaude AIを実行するためのコンテナ化環境が含まれています：

- `bin/ccc`: Claudeをコンテナで実行するスクリプト
  - 自動更新確認機能（1日に1回）
  - カラフルなロゴ表示と使いやすいインターフェース
  - 複数ソースパスのマウント
  - コンテナ自動削除機能（--rm付き実行）
- `bin/diagnose-claude.sh`: Claude環境を診断するユーティリティ
- `bin/container-runner`: Dockerコンテナを実行するための汎用ユーティリティ
- `compose.yml`: コンテナ化環境のDocker Compose設定
- `etc/dockerfiles/claude-code/`: Claudeコンテナ用のDockerfileとセットアップスクリプト
- `etc/dockerfiles/playwright-mcp/`: Playwright MCPコンテナ用のDockerfile

## 一般的なコマンド

### コンテナでClaudeを実行する

```bash
# 現在のディレクトリをマウントしてClaudeをコンテナで実行
./bin/ccc

# 特定のソースディレクトリを指定してClaudeを実行
./bin/ccc -s /path/to/source

# 複数のソースディレクトリをマウントしてClaudeを実行
./bin/ccc -s /path/to/source1 -s /path/to/source2

# 詳細情報を表示
./bin/ccc --info --verbose

# Claudeイメージの更新を確認
./bin/ccc --check-update

# Claudeイメージを更新
./bin/ccc --update

# 孤立したコンテナも削除（デフォルトは削除しない）
./bin/ccc --rm-orphans

# compose.yml内に定義されたMCPサービスをClaudeで利用可能にする
./bin/ccc --mcp memory --mcp playwright

# AWS Bedrockと特定のMCPを組み合わせて使用
./bin/ccc --bedrock --mcp sequentialthinking
```

### Claude環境の診断

```bash
# Claude環境の診断
./bin/diagnose-claude.sh
```

### Dockerコンテナ管理

```bash
# コンテナ化されたClaudeサービスを起動
docker compose up containered-claude

# Claudeコンテナイメージをビルド
docker compose build containered-claude

# Playwrightコンテナを起動
docker compose up playwright

# 孤立したコンテナを削除
docker compose down --remove-orphans
```

### Dockerイメージの操作

```bash
# 宙ぶらりんのDockerイメージを削除
docker rmi $(docker images -f "dangling=true" -q)

# すべてのコンテナを削除
docker rm $(docker ps -a -q)
```

## 開発環境セットアップ

新しい環境のセットアップ方法：

### Linux/Ubuntu

```bash
# Linux用セットアップスクリプトを実行
./bin/setup.sh
```

### Windows

```powershell
# Windows用セットアップスクリプトを実行
Invoke-Command -ScriptBlock ([scriptblock]::Create((new-object net.webclient).downloadstring("https://raw.github.com/njfa/dotfiles/main/bin/setup.ps1"))) -ArgumentList "init"
```

## Neovim設定

このリポジトリにはAIコーディングアシスタントをサポートする包括的なNeovimセットアップが含まれています：

- GitHub Copilotの統合は環境変数で有効/無効を切り替え可能
- Copilotバックエンド付きのAIアシストコーディング用CodeCompanionプラグイン

## アーキテクチャメモ

- リポジトリはOS固有の初期化スクリプトによるモジュラーアプローチを使用
- OS検出とバージョン固有の設定が実装されている
- コンテナ設定には適切なセキュリティ対策（ファイアウォールスクリプト）が含まれる
- `zshrc`ファイルには開発ワークフロー用の広範なカスタム関数が含まれる

## コミットガイドライン

このリポジトリでコミットを作成する際は以下のガイドラインに従ってください：

### Conventional Commit Specification

すべてのコミットメッセージは[Conventional Commit specification](https://www.conventionalcommits.org/)に従って記述します：

```txt
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### コミットタイプ

- `feat`: 新機能の追加
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響を与えない変更（空白、フォーマット、セミコロンの欠落等）
- `refactor`: バグ修正や機能追加を含まないコードの変更
- `perf`: パフォーマンスを向上させるコードの変更
- `test`: テストの追加や既存テストの修正
- `build`: ビルドシステムや外部依存関係に影響を与える変更
- `ci`: CI設定ファイルやスクリプトの変更
- `chore`: その他の変更（ドキュメント生成など）

### コミットメッセージの例

```txt
feat: デプロイメント自動化スクリプトを追加
```

```txt
fix: 環境変数の読み込みエラーを修正

環境変数が設定されていない場合のデフォルト値を追加。
これにより初回セットアップ時のエラーを防ぐ。
```

### 注意事項

- **重要**: co-author情報（`Co-Authored-By`など）は絶対に記載しません
- **重要**: Claude生成メッセージのフッター（「🤖 Generated with Claude Code」など）も含めません
- コミットメッセージは日本語で記述します
- 最初の行は50文字以内に収めます
- 本文が必要な場合は空行を挟んで記述します

