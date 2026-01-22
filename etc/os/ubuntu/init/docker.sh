#!/bin/bash

if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
fi

if ! getent group docker >/dev/null 2>&1; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER
