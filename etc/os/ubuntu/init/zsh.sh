#!/bin/bash

eval "ZSH_VERSION=$ZSH_VERSION"

# zshのインストール
if [ -z "$(command -v zsh)" -o "$(zsh --version | awk '{print $2}')" != "$ZSH_VERSION" ]; then
    sudo apt install -y wget tar make
    wget https://sourceforge.net/projects/zsh/files/zsh/$ZSH_VERSION/zsh-$ZSH_VERSION.tar.xz/download -O zsh-$ZSH_VERSION.tar.xz
    tar xvf zsh-$ZSH_VERSION.tar.xz -C ~/
    rm zsh-$ZSH_VERSION.tar.xz
    mv ~/zsh-$ZSH_VERSION ~/.zsh
    cd ~/.zsh
    ./configure --enable-multibyte
    make && sudo make install
fi

# /etc/shellsに含まれていない場合は追加
if [ -z "$(cat /etc/shells | grep $(which zsh))" ]; then
    sudo sh -c "echo $(which zsh) >> /etc/shells"
fi

# zinitのインストール
if [ ! -d "$HOME/.zinit" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
fi