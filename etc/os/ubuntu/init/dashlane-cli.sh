#!/bin/bash

set -eu

if command -v dashlane-cli >/dev/null 2>&1; then
    echo "dashlane-cli is installed."
    exit 0
fi

export NONINTERACTIVE=1

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
else
    echo "brew command is unavailable after Homebrew installation." >&2
    exit 1
fi

if brew list dashlane/tap/dashlane-cli >/dev/null 2>&1; then
    echo "dashlane-cli is already installed via Homebrew."
else
    brew install dashlane/tap/dashlane-cli
fi
