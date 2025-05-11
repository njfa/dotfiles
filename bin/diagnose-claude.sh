#!/bin/bash

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 情報ログ表示関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# ヘッダー表示
echo -e "${BOLD}Claude Container 診断ユーティリティ${NC}"
echo "==============================================="
echo

# システム情報の表示
log_info "システム情報の取得中..."
echo "オペレーティングシステム: $(uname -s)"
echo "カーネルバージョン: $(uname -r)"

# Dockerの確認
log_info "Dockerの確認中..."
if ! command -v docker &> /dev/null; then
    log_error "Dockerが見つかりません。インストールしてください。"
    exit 1
else
    docker_version=$(docker --version)
    log_success "Docker が利用可能です: $docker_version"
fi

# Docker Composeの確認
log_info "Docker Composeの確認中..."
if ! docker compose version &> /dev/null; then
    log_warning "Docker Composeが見つかりません。Docker Composeをインストールするか、Docker Desktopを使用してください。"
else
    compose_version=$(docker compose version)
    log_success "Docker Compose が利用可能です: $compose_version"
fi

# 必要なコマンドの確認
log_info "必要なコマンドの確認中..."
for cmd in yq jq npm; do
    if ! command -v $cmd &> /dev/null; then
        log_warning "$cmd が見つかりません。一部の機能が制限される可能性があります。"
    else
        log_success "$cmd が利用可能です: $($cmd --version)"
    fi
done

# 必要なファイルの確認
log_info "必要なファイルの確認中..."
DOTFILES_DIR="$HOME/.dotfiles"
CONTAINER_RUNNER="$DOTFILES_DIR/bin/container-runner"
CCC_SCRIPT="$DOTFILES_DIR/bin/ccc"
COMPOSE_FILE="$DOTFILES_DIR/compose.yml"

if [ ! -f "$CONTAINER_RUNNER" ]; then
    log_warning "container-runnerスクリプトが見つかりません: $CONTAINER_RUNNER"
else
    log_success "container-runnerスクリプトが利用可能です"
fi

if [ ! -f "$CCC_SCRIPT" ]; then
    log_warning "cccスクリプトが見つかりません: $CCC_SCRIPT"
else
    log_success "cccスクリプトが利用可能です"
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    log_warning "Docker Composeファイルが見つかりません: $COMPOSE_FILE"
else
    log_success "Docker Composeファイルが利用可能です"
fi

# Claude認証情報の確認
log_info "Claude認証情報の確認中..."
CLAUDE_CREDENTIAL_PATH="${CLAUDE_CREDENTIAL_PATH:-$HOME/.claude}"
CLAUDE_CONFIG_PATH="${CLAUDE_CONFIG_PATH:-$HOME/.claude.json}"

if [ ! -d "$CLAUDE_CREDENTIAL_PATH" ]; then
    log_warning "Claude認証情報ディレクトリが見つかりません: $CLAUDE_CREDENTIAL_PATH"
else
    log_success "Claude認証情報ディレクトリが利用可能です"
fi

if [ ! -f "$CLAUDE_CONFIG_PATH" ]; then
    log_warning "Claude設定ファイルが見つかりません: $CLAUDE_CONFIG_PATH"
else
    log_success "Claude設定ファイルが利用可能です"
fi

# イメージの確認
log_info "Dockerイメージの確認中..."
if ! docker image inspect my-claude-code:latest &> /dev/null; then
    log_warning "Claude Codeイメージが見つかりません。イメージをビルドする必要があります。"
    echo "以下のコマンドでイメージをビルドしてください:"
    echo "docker compose -f $COMPOSE_FILE build containered-claude"
else
    log_success "Claude Codeイメージが利用可能です"
    
    # イメージ内のclaude-codeバージョンの確認を試みる
    container_version=$(docker run --rm my-claude-code:latest npm list -g @anthropic-ai/claude-code --json 2>/dev/null | jq -r '.dependencies."@anthropic-ai/claude-code".version' 2>/dev/null)
    
    if [ -n "$container_version" ] && [ "$container_version" != "null" ]; then
        log_success "インストールされているClaude Codeバージョン: $container_version"
        
        # 最新バージョンの確認を試みる
        latest_version=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
        if [ -n "$latest_version" ]; then
            if [ "$container_version" != "$latest_version" ]; then
                log_warning "利用可能な更新があります: $container_version → $latest_version"
                echo "以下のコマンドで更新できます:"
                echo "$CCC_SCRIPT --update"
            else
                log_success "Claude Codeは最新バージョンです"
            fi
        fi
    else
        log_warning "Claude Codeのバージョン情報を取得できませんでした"
    fi
fi

# ネットワーク接続の確認
log_info "ネットワーク接続の確認中..."
if ping -c 1 api.anthropic.com &> /dev/null; then
    log_success "api.anthropic.comに接続できます"
else
    log_warning "api.anthropic.comに接続できません。ネットワーク設定を確認してください。"
fi

# 総合評価
echo
echo "==============================================="
log_info "診断完了"
echo
echo "問題が見つかった場合は以下を確認してください:"
echo "1. Dockerとその依存関係が正しくインストールされていること"
echo "2. Claude認証情報と設定ファイルが正しい場所にあること"
echo "3. 必要なスクリプトとファイルが利用可能であること"
echo
echo "詳細なトラブルシューティングは README-CLAUDE.md を参照してください。"