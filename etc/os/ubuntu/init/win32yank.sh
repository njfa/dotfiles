#!/bin/bash

set -eu

is_wsl() {
    test -n "${WSL_DISTRO_NAME:-}" || grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
}

if ! is_wsl; then
    echo "win32yank.exe install supports WSL only."
    exit 0
fi

if command -v win32yank.exe >/dev/null 2>&1; then
    echo "win32yank.exe is installed."
    exit 0
fi

if [ -z "${USERPROFILE:-}" ]; then
    echo "USERPROFILE is not set."
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
    echo "Installing Rust for building win32yank..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi

WIN32YANK_PATH="$HOME/.win32yank"
if [ ! -d "$WIN32YANK_PATH" ]; then
    git clone https://github.com/equalsraf/win32yank.git "$WIN32YANK_PATH"
fi

cd "$WIN32YANK_PATH"

if [ -n "${DOTFILES_ARCH_TYPE:-}" ] && [ "$DOTFILES_ARCH_TYPE" = "arm64" ]; then
    target="aarch64-pc-windows-gnu"
else
    target="x86_64-pc-windows-gnu"
fi

rustup target add "$target"
cargo build --release --target="$target"

windows_bin_dir="$(wslpath -u "$USERPROFILE/bin")"
mkdir -p "$windows_bin_dir"
cp "target/$target/release/win32yank.exe" "$windows_bin_dir/"
