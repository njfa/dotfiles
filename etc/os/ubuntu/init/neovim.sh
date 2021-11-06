#!/bin/bash

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [ -z "$(command -v pip)" ]; then
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/python.sh
    eval "$(pyenv init -)"
fi

if [ -z "$(command -v nvim)" ]; then
    sudo add-apt-repository ppa:neovim-ppa/stable
    sudo apt update
    sudo apt install -y neovim
fi

if [ ! -z "$(command -v python)" -a ! -z "$(command -v pip)" -a -z "$(pip list | grep pynvim)" ]; then
    pip install pynvim
fi

if [ ! -f "${XDG_DATA_HOME:-$HOME}/.local/share/nvim/site/autoload/plug.vim" ]; then
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi
