#!/bin/bash

# Goのインストール
if [ -z "$(command -v go)" ]; then
    # 公式から最新安定版のバージョンを取得
    LATEST_VERSION=$(curl -s "https://go.dev/dl/?mode=json" | jq -r '.[].version' | grep -o 'go[0-9.]*' | head -1 | cut -d'"' -f4 | sed 's/go//')

    # アーキテクチャを判定
    ARCH=$(uname -m)
    case $ARCH in
    x86_64)
        ARCH_NAME="amd64"
        ;;
    aarch64 | arm64)
        ARCH_NAME="arm64"
        ;;
    i686 | i386)
        ARCH_NAME="386"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    # ダウンロードURL
    DOWNLOAD_URL="https://go.dev/dl/go${LATEST_VERSION}.linux-${ARCH_NAME}.tar.gz"

    # 一時ディレクトリでダウンロード
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    echo "Downloading Go ${LATEST_VERSION} for ${ARCH_NAME}..."
    curl -Lo go.tar.gz "$DOWNLOAD_URL"

    # 既存のGoがある場合は削除
    sudo rm -rf /usr/local/go

    # 解凍してインストール
    sudo tar -C /usr/local -xzf go.tar.gz

    # クリーンアップ
    cd -
    rm -rf "$TMP_DIR"

    # パスの設定を追加（まだ設定されていない場合）
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
        echo 'export PATH=$PATH:$(go env GOPATH)/bin' >>~/.bashrc
    fi

    # 現在のシェルでもパスを設定
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$(go env GOPATH)/bin

    echo "Go ${LATEST_VERSION} installed successfully"
    echo "Please run 'source ~/.bashrc' or restart your terminal to update PATH"
fi

# Goツールのインストール
if [ -n "$(command -v go)" ]; then
    # memoツールのインストール
    if [ -z "$(command -v memo)" ]; then
        echo "Installing memo..."
        go install github.com/mattn/memo@latest
    fi

    # その他の便利なGoツール（オプション）
    # golangci-lint（Go用の高機能リンター）
    if [ -z "$(command -v golangci-lint)" ]; then
        echo "Installing golangci-lint..."
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin
    fi
fi
