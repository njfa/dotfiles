#!/bin/bash

TMUX_PATH=~/.tmux

if [ ! -d "$TMUX_PATH" ]; then
    sudo apt install -y git automake bison build-essential pkg-config libevent-dev libncurses5-dev

    git clone https://github.com/tmux/tmux $TMUX_PATH

    cd $TMUX_PATH
    ./autogen.sh
    ./configure --prefix=/usr/local
    make
    sudo make install
    tmux -V
fi

if [ ! -z "$USERPROFILE" -a -z "$(command -v win32yank.exe)" ]; then
    # WSL環境でwin32yankをソースからビルド
    # Rustが必要
    if ! command -v cargo >/dev/null 2>&1; then
        echo "Installing Rust for building win32yank..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi

    # win32yankをクローンしてビルド
    WIN32YANK_PATH=$HOME/.win32yank
    if [ ! -d "$WIN32YANK_PATH" ]; then
        git clone https://github.com/equalsraf/win32yank.git $WIN32YANK_PATH
        cd $WIN32YANK_PATH

        # Windows用のターゲットを追加（WSLからクロスコンパイル）
        if [ -n "$DOTFILES_ARCH_TYPE" ] && [ "$DOTFILES_ARCH_TYPE" = "arm64" ]; then
            rustup target add aarch64-pc-windows-gnu
            cargo build --release --target=aarch64-pc-windows-gnu
            cp target/aarch64-pc-windows-gnu/release/win32yank.exe $(wslpath -u "$USERPROFILE/bin")/
        else
            rustup target add x86_64-pc-windows-gnu
            cargo build --release --target=x86_64-pc-windows-gnu
            cp target/x86_64-pc-windows-gnu/release/win32yank.exe $(wslpath -u "$USERPROFILE/bin")/
        fi

        cd -
    fi
fi
