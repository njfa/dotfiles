#!/bin/bash

eval "PYTHON_VERSION=$PYTHON_VERSION"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# pyenvのインストール
pyenv --version && eval "$(pyenv init -)" || if [ -z "$(command -v pyenv)" ]; then
    git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT

    eval "$(pyenv init -)"
fi

pyenv versions | grep $PYTHON_VERSION || if [ -n "$(command -v pyenv)" ]; then
    # dependencies
    sudo apt update -y
    sudo apt install -y --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    pyenv install $PYTHON_VERSION
    pyenv global $PYTHON_VERSION
fi

python --version || exit 1
pip --version || exit 1
pip install --upgrade pip
