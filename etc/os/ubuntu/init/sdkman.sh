#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Skipping sdkman: sudo is unavailable and current user is not root." >&2
    exit 0
fi

if [ -z "$(command -v zip)" ]; then
    $SUDO apt install -y zip
fi

if [ -z "$(command -v unzip)" ]; then
    $SUDO apt install -y unzip
fi

if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
fi
