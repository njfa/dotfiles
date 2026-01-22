#!/bin/bash

if command -v fontforge >/dev/null 2>&1; then
    echo "fontforge is installed."
    exit 0
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

if [ "${ID:-}" != "ubuntu" ]; then
    echo "fontforge install supports Ubuntu only."
    exit 0
fi

sudo apt-get update -y
sudo apt-get install -y software-properties-common

case "${VERSION_ID:-}" in
18.04)
    sudo add-apt-repository ppa:fontforge/fontforge
    sudo apt-get update -y
    sudo apt-get install -y fontforge python-fontforge
    ;;
20.04)
    sudo add-apt-repository ppa:fontforge/fontforge
    sudo apt-get update -y
    sudo apt-get install -y fontforge python3-fontforge
    ;;
*)
    sudo apt-get install -y fontforge python3-fontforge
    ;;
esac
