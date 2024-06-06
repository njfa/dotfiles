#!/bin/bash

PYENV_ROOT="$HOME/.pyenv"
PATH="$PYENV_ROOT/bin:$PATH"

if command -v pip >/dev/null 2>&1; then
    echo "pip is installed."
else
    echo "pip is not installed."
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/python.sh
    eval "$(pyenv init -)"
fi

if pip list | grep pynvim >/dev/null 2>&1; then
    echo "pynvim is installed."
else
    echo "pynvim is not installed."
    pip install pynvim
fi

if command -v rg >/dev/null 2>&1; then
    echo "ripgrep is installed."
else
    echo "ripgrep is not installed."
    sudo apt install -y ripgrep
fi

if command -v fdfind >/dev/null 2>&1; then
    echo "fd-find is installed."
else
    echo "fd-find is not installed."
    sudo apt install -y fd-find
fi

is_installed=false

# ダウンロード先のディレクトリを生成
[ ! -d "$HOME/.nvim" ] && mkdir ~/.nvim

if command -v nvim >/dev/null 2>&1; then
    version="$(nvim --version | grep "NVIM" | awk '{print $2}')"
    echo "neovim is installed. required version: $NEOVIM_VERSION. now version: $version"

    [ "$version" = "$NEOVIM_VERSION" ] && is_installed=true
else
    echo "neovim is not installed. required version: $NEOVIM_VERSION."
fi

if ! $is_installed; then
    if [ ! -d "$HOME/.nvim/$NEOVIM_VERSION" ]; then
        echo "neovim is not downloaded."

        curl -Lo nvim.appimage https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim.appimage
        chmod u+x nvim.appimage && ./nvim.appimage --appimage-extract
        mv squashfs-root ~/.nvim/$NEOVIM_VERSION
        rm nvim.appimage
    else
        echo "neovim is already downloaded."
    fi

    sudo ln -sf ~/.nvim/$NEOVIM_VERSION/usr/bin/nvim /usr/local/bin/nvim
    rm -rf ~/.config/nvim/plugin/packer_compiled.lua ~/.local/share/nvim
fi
