#!/bin/bash

eval "PYTHON_VERSION=$PYTHON_VERSION"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# pyenvのインストール
if [ -z "$(command -v pyenv)" ]; then
    git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT
fi

eval "$(pyenv init -)"

if [ -z "$(pyenv versions | grep $PYTHON_VERSION)" ]; then
    # dependencies
    sudo apt update -y
    sudo apt install -y --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    pyenv install $PYTHON_VERSION
    pyenv global $PYTHON_VERSION
fi

if [ -z "$(command -v python)" ]; then
    exit 1
elif [ -z "$(command -v pip)" ]; then
    exit 1
fi

if [ ! -z "$(pip list --outdated | grep pip)" ]; then
    pip install --upgrade pip
fi
