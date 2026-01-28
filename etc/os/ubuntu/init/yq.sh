#!/bin/bash

if command -v yq >/dev/null 2>&1; then
    echo "yq is installed."
else
    echo "yq is not installed."

    if [ ! -d "$HOME/.yq/bin" ]; then
        mkdir -p $HOME/.yq/bin
    fi

    # アーキテクチャに応じたバイナリを選択
    # setup.shから環境変数が設定されている場合はそれを使用
    if [ -n "$DOTFILES_ARCH_TYPE" ]; then
        arch_suffix=$DOTFILES_ARCH_TYPE
    else
        # フォールバック: 直接アーキテクチャを検出
        case $(uname -m) in
            x86_64)
                arch_suffix="amd64"
                ;;
            aarch64|arm64)
                arch_suffix="arm64"
                ;;
            *)
                echo "Unsupported architecture: $(uname -m)"
                exit 1
                ;;
        esac
    fi

    echo "Downloading yq for architecture: $arch_suffix"
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch_suffix} -O $HOME/.yq/bin/yq
    chmod +x $HOME/.yq/bin/yq

    sudo ln -sf ~/.yq/bin/yq /usr/local/bin/yq
fi

