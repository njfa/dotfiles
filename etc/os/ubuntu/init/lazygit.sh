#!/bin/sh

is_installed=false

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

if [ -n "$(command -v lazygit)" ]; then
    version=$(lazygit --version | awk '{print $6}' | grep -o 'version=[^,]*' | awk -F= '{print $2}')
    echo "lazygit is installed. required version: $LAZYGIT_VERSION. now version: $version"

    [ "$version" = "$LAZYGIT_VERSION" ] && is_installed=true
else
    echo "lazygit is not installed. required version: $LAZYGIT_VERSION."
fi

if ! $is_installed; then
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -rf lazygit lazygit.tar.gz
fi
