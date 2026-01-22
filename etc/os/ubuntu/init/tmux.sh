#!/bin/bash

TMUX_SRC_ROOT="$HOME/.tmux"
TMUX_INSTALL_ROOT="$HOME/.local/tmux"

if [ -z "${TMUX_VERSION:-}" ]; then
    echo "TMUX_VERSION is not set."
    exit 1
fi

current_version=""
if command -v tmux >/dev/null 2>&1; then
    current_version="$(tmux -V 2>/dev/null | awk '{print $2}')"
fi

if [ "$current_version" != "$TMUX_VERSION" ]; then
    sudo apt install -y automake bison build-essential pkg-config libevent-dev libncurses5-dev

    ARCHIVE_NAME="tmux-${TMUX_VERSION}.tar.gz"
    SRC_DIR="${TMUX_SRC_ROOT}/tmux-${TMUX_VERSION}"
    INSTALL_DIR="${TMUX_INSTALL_ROOT}/${TMUX_VERSION}"

    mkdir -p "$TMUX_SRC_ROOT" "$TMUX_INSTALL_ROOT"

    if [ ! -d "$SRC_DIR" ]; then
        curl -fsSL "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/${ARCHIVE_NAME}" -o "/tmp/${ARCHIVE_NAME}"
        mkdir -p "$SRC_DIR"
        tar -xzf "/tmp/${ARCHIVE_NAME}" -C "$SRC_DIR" --strip-components=1
        rm -f "/tmp/${ARCHIVE_NAME}"
    fi

    cd "$SRC_DIR"
    ./configure --prefix="$INSTALL_DIR"
    make
    make install

    sudo ln -sf "$INSTALL_DIR/bin/tmux" /usr/local/bin/tmux
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
