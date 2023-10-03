#!/bin/bash

docker version || if [ -z "$(command -v docker)" ]; then
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
fi


if [ "$(docker compose version 2>/dev/null)" ]; then
    sudo apt-get install -y docker-compose-plugin
    docker compose version
fi
