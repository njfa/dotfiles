#!/bin/bash

if [ -z "$(command -v inframap)" ]; then
    # inframapの最新バージョンを取得
    LATEST_VERSION=$(curl -s https://api.github.com/repos/cycloidio/inframap/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

    # アーキテクチャを判定
    ARCH=$(uname -m)
    case $ARCH in
    x86_64)
        ARCH_NAME="amd64"
        ;;
    aarch64 | arm64)
        ARCH_NAME="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
    esac

    # ダウンロードURL
    DOWNLOAD_URL="https://github.com/cycloidio/inframap/releases/download/v${LATEST_VERSION}/inframap-linux-${ARCH_NAME}.tar.gz"

    # 一時ディレクトリでダウンロードと解凍
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    echo "Downloading inframap v${LATEST_VERSION} for ${ARCH_NAME}..."
    curl -Lo inframap.tar.gz "$DOWNLOAD_URL"
    tar -xzf inframap.tar.gz

    # inframapバイナリを探して移動（パターンマッチで検索）
    INFRAMAP_BINARY=$(find . -name "inframap-linux-*" -type f 2>/dev/null | head -1)
    if [ -n "$INFRAMAP_BINARY" ] && [ -f "$INFRAMAP_BINARY" ]; then
        sudo mv "$INFRAMAP_BINARY" /usr/local/bin/inframap
    else
        echo "Error: inframap binary not found in archive"
        echo "Archive contents:"
        find . -type f -ls
        cd -
        rm -rf "$TMP_DIR"
        exit 1
    fi

    sudo chmod +x /usr/local/bin/inframap

    # クリーンアップ
    cd -
    rm -rf "$TMP_DIR"

    echo "inframap v${LATEST_VERSION} installed successfully"
fi
