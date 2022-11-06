#!/bin/bash

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [ -z "$(command -v pip)" ]; then
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/python.sh
    eval "$(pyenv init -)"
fi

if [ -z "$(command -v nvim)" ]; then
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt update
    sudo apt install -y neovim
fi

if [ -z "$(command -v rg)" ]; then
    sudo apt install -y ripgrep
fi

if [ -z "$(command -v fdfind)" ]; then
    sudo apt install -y fd-find
fi

if [ ! -z "$(command -v python)" -a ! -z "$(command -v pip)" -a -z "$(pip list | grep pynvim)" ]; then
    pip install pynvim
fi
