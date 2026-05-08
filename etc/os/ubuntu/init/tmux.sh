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
