#!/bin/bash

if ! command -v docker >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    sudo groupadd docker
    sudo usermod -aG docker $USER

    sudo service docker start
    docker version
elif service docker status || sudo service docker start; then
    docker version
else
    exit 1
fi

if ! docker compose version; then
    sudo apt-get install -y docker-compose-plugin
    docker compose version
fi
