#!/bin/bash

set -eu

if command -v dcli >/dev/null 2>&1; then
    echo "dcli is installed."
    exit 0
fi

REAL_HOME="$HOME"
brew_prefix="/home/linuxbrew/.linuxbrew"
created_brew_prefix=0

cleanup() {
    if [ "$created_brew_prefix" -eq 1 ]; then
        sudo rm -rf "$brew_prefix"
    fi
}

trap cleanup EXIT

export NONINTERACTIVE=1
export HOMEBREW_NO_ANALYTICS=1

if [ ! -x "$brew_prefix/bin/brew" ]; then
    if [ ! -d "$brew_prefix" ]; then
        sudo install -d -o "$USER" -g "$USER" "$brew_prefix"
    fi

    mkdir -p "$brew_prefix/Homebrew" "$brew_prefix/bin"
    curl -fsSL https://github.com/Homebrew/brew/tarball/HEAD | tar xz --strip 1 -C "$brew_prefix/Homebrew"
    ln -s ../Homebrew/bin/brew "$brew_prefix/bin/brew"
    created_brew_prefix=1
fi

mkdir -p "$REAL_HOME/.local/bin"
eval "$("$brew_prefix/bin/brew" shellenv)"
brew install dashlane/tap/dashlane-cli

dcli_path="$brew_prefix/bin/dcli"

if [ ! -x "$dcli_path" ]; then
    echo "dcli executable was not installed at $dcli_path." >&2
    exit 1
fi

cp "$dcli_path" "$REAL_HOME/.local/bin/dcli"

if ldd "$REAL_HOME/.local/bin/dcli" | grep -F "$brew_prefix" >/dev/null 2>&1; then
    echo "dcli still depends on Homebrew files." >&2
    rm -f "$REAL_HOME/.local/bin/dcli"
    exit 1
fi

echo "dcli is installed to $REAL_HOME/.local/bin/dcli."
