#!/bin/bash

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [ -z "$(command -v pip)" ]; then
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/python.sh
    eval "$(pyenv init -)"
fi

if [ -z "$(command -v nvim)" ]; then
    sudo apt install -y neovim
fi

if [ ! -z "$(command -v python)" -a ! -z "$(command -v pip)" -a -z "$(pip list | grep pynvim)" ]; then
    pip install pynvim
fi
