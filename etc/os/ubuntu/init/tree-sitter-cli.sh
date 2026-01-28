#!/bin/bash

is_installed=false

if [ -z "$TREESITTER_VERSION" ]; then
    echo "tree-sitter-cli required version is not defined."
    exit 1
fi

if command -v tree-sitter >/dev/null 2>&1; then
    version="$(tree-sitter --version | awk '{print $2}')"
    echo "tree-sitter-cli is installed. required version: $TREESITTER_VERSION. now version: $version."

    [ "$version" = "$TREESITTER_VERSION" ] && is_installed=true
else
    echo "tree-sitter-cli is not installed. required version: $TREESITTER_VERSION."
fi

# ダウンロード先のディレクトリを生成
[ ! -d "$HOME/.tree-sitter-cli" ] && mkdir ~/.tree-sitter-cli

if ! $is_installed; then
    if [ ! -d "$HOME/.tree-sitter-cli/$TREESITTER_VERSION" ]; then
        # CPUアーキテクチャを検出
        arch=$(uname -m)
        case "$arch" in
        x86_64)
            archive_filename="tree-sitter-linux-x64.gz"
            ;;
        aarch64 | arm64)
            archive_filename="tree-sitter-linux-arm64.gz"
            ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
        esac

        download_url="https://github.com/tree-sitter/tree-sitter/releases/download/${TREESITTER_VERSION}/${archive_filename}"

        echo "Detected architecture: $arch"
        echo "Trying to download: ${download_url}"
        if ! curl -fLo "$archive_filename" "$download_url"; then
            echo "Error: Failed to download ${archive_filename}"
            echo "Please check if version ${TREESITTER_VERSION} exists and supports your architecture"
            exit 1
        fi

        mkdir -p "$HOME/.tree-sitter-cli/$TREESITTER_VERSION"

        gunzip "$archive_filename"
        extracted_file="${archive_filename%.gz}"
        mv $extracted_file "$HOME/.tree-sitter-cli/$TREESITTER_VERSION/tree-sitter"
        if [ ! -f "$HOME/.tree-sitter-cli/$TREESITTER_VERSION/tree-sitter" ]; then
            echo "Error: Expected file $HOME/.tree-sitter-cli/$TREESITTER_VERSION/tree-sitter not found after extraction"
            exit 1
        fi

        chmod +x "$HOME/.tree-sitter-cli/$TREESITTER_VERSION/tree-sitter"
    else
        echo "tree-sitter-cli is already downloaded."
    fi

    sudo ln -sf ~/.tree-sitter-cli/$TREESITTER_VERSION/tree-sitter /usr/local/bin/tree-sitter
fi

