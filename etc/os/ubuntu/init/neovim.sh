#!/bin/sh

PYENV_ROOT="$HOME/.pyenv"
PATH="$PYENV_ROOT/bin:$PATH"

if [ -z "$(command -v pip)" ]; then
    echo "pip is not installed."
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/python.sh
    eval "$(pyenv init -)"
else
    echo "pip is installed."
fi

if [ -n "$(command -v pip)" -a -z "$(pip list | grep pynvim)" ]; then
    echo "pynvim is not installed."
    pip install pynvim
else
    echo "pynvim is installed."
fi

if [ -z "$(command -v rg)" ]; then
    echo "ripgrep is not installed."
    sudo apt install -y ripgrep
else
    echo "ripgrep is installed."
fi

if [ -z "$(command -v fdfind)" ]; then
    echo "fd-find is not installed."
    sudo apt install -y fd-find
else
    echo "fd-find is installed."
fi

is_installed=false
is_downloaded=false

# ダウンロード先のディレクトリを生成
[ ! -d "$HOME/.nvim" ] && mkdir ~/.nvim

if [ -n "$(command -v nvim)" ]; then
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
        echo "neovim is downloaded."
    fi

    sudo ln -sf ~/.nvim/$NEOVIM_VERSION/usr/bin/nvim /usr/local/bin/nvim
    rm -rf ~/.config/nvim/plugin/packer_compiled.lua ~/.local/share/nvim
fi
