#!/bin/bash

if [ -z "$(command -v terraform-docs)" ]; then
    # terraform-docsの最新バージョンを取得
    LATEST_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

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
    DOWNLOAD_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${LATEST_VERSION}/terraform-docs-v${LATEST_VERSION}-linux-${ARCH_NAME}.tar.gz"

    # 一時ディレクトリでダウンロードと解凍
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    echo "Downloading terraform-docs v${LATEST_VERSION} for ${ARCH_NAME}..."
    curl -Lo terraform-docs.tar.gz "$DOWNLOAD_URL"
    tar -xzf terraform-docs.tar.gz

    # インストール
    sudo mv terraform-docs /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform-docs

    # クリーンアップ
    cd -
    rm -rf "$TMP_DIR"

    echo "terraform-docs v${LATEST_VERSION} installed successfully"
fi
