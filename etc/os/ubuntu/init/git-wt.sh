#!/bin/sh

if [ -z "${GIT_WT_VERSION:-}" ]; then
    echo "GIT_WT_VERSION is not set."
    exit 1
fi

is_installed=false

if command -v git-wt >/dev/null 2>&1; then
    echo "git-wt is installed. required version: $GIT_WT_VERSION."
else
    echo "git-wt is not installed. required version: $GIT_WT_VERSION."
fi

# deltaのインストール
if ! $is_installed; then
    if [ ! -d "$HOME/.git-wt/$GIT_WT_VERSION" ]; then
        echo "git-wt is not downloaded."

        # ダウンロード先のディレクトリを生成
        [ ! -d "$HOME/.git-wt/$GIT_WT_VERSION" ] && mkdir -p "$HOME/.git-wt/$GIT_WT_VERSION"

        # CPUアーキテクチャを検出
        arch=$(uname -m)
        case "$arch" in
        x86_64)
            archive_filename="git-wt_${GIT_WT_VERSION}_linux_amd64.tar.gz"
            ;;
        aarch64 | arm64)
            archive_filename="git-wt_${GIT_WT_VERSION}_linux_arm64.tar.gz"
            ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
        esac

        download_url="https://github.com/k1LoW/git-wt/releases/download/${GIT_WT_VERSION}/${archive_filename}"
        echo "Detected architecture: $arch"
        echo "Trying to download: ${download_url}"
        if ! curl -fLo "$archive_filename" "$download_url"; then
            echo "Error: Failed to download ${archive_filename}"
            echo "Please check if version ${GIT_WT_VERSION} exists and supports your architecture"
            exit 1
        fi

        tar -xf "$archive_filename"

        mv git-wt ~/.git-wt/$GIT_WT_VERSION
        rm -f "$archive_filename"
    else
        echo "git-wt is already downloaded."
    fi

    sudo ln -sf ~/.git-wt/$GIT_WT_VERSION/git-wt /usr/local/bin/git-wt
fi
