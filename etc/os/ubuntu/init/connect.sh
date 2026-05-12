#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Skipping connect: sudo is unavailable and current user is not root." >&2
    exit 0
fi

if command -v connect >/dev/null 2>&1; then
    echo "connect is installed."
else
    echo "connect is not installed."
    $SUDO apt install -y connect-proxy
fi
