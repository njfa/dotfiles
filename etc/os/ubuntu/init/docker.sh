#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Skipping docker: sudo is unavailable and current user is not root." >&2
    exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    $SUDO sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
fi

if ! getent group docker >/dev/null 2>&1; then
    $SUDO groupadd docker
fi
$SUDO usermod -aG docker $USER
