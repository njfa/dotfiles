#!/bin/bash

if [ -z "${TREESITTER_VERSION:-}" ]; then
    echo "TREESITTER_VERSION is not set."
    exit 1
fi

install_root="$HOME/.tree-sitter-cli/$TREESITTER_VERSION"
binary_path="$install_root/bin/tree-sitter"
crate_version="${TREESITTER_VERSION#v}"
is_installed=false

if [ -z "${LIBCLANG_PATH:-}" ]; then
    for candidate in \
        /usr/lib/llvm-*/lib \
        /usr/lib/x86_64-linux-gnu \
        /usr/lib/aarch64-linux-gnu
    do
        for dir in $candidate; do
            if [ -d "$dir" ] && find "$dir" -maxdepth 1 -name 'libclang.so*' | grep -q .; then
                export LIBCLANG_PATH="$dir"
                break 2
            fi
        done
    done
fi

if command -v tree-sitter >/dev/null 2>&1 && tree-sitter --version >/dev/null 2>&1; then
    version="$(tree-sitter --version | awk '{print $2}')"
    echo "tree-sitter-cli is installed. required version: $TREESITTER_VERSION. now version: $version."

    [ "${version#v}" = "$crate_version" ] && is_installed=true
else
    echo "tree-sitter-cli is not installed or unusable. required version: $TREESITTER_VERSION."
fi

[ ! -d "$HOME/.tree-sitter-cli" ] && mkdir -p "$HOME/.tree-sitter-cli"

if ! $is_installed; then
    if ! command -v cargo >/dev/null 2>&1; then
        if [ -f "$HOME/.cargo/env" ]; then
            . "$HOME/.cargo/env"
        fi
    fi

    if ! command -v cargo >/dev/null 2>&1; then
        echo "cargo is not installed. Installing rustup first..."
        curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
    fi

    if [ ! -x "$binary_path" ]; then
        mkdir -p "$install_root"
        cargo install \
            --locked \
            --root "$install_root" \
            tree-sitter-cli \
            --version "$crate_version"
    else
        echo "tree-sitter-cli is already built."
    fi

    if [ ! -x "$binary_path" ]; then
        echo "Error: Expected binary $binary_path not found after cargo install"
        exit 1
    fi

    sudo ln -sf "$binary_path" /usr/local/bin/tree-sitter
fi
