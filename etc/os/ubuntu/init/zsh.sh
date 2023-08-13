#!/bin/sh

is_installed=false

if [ -n "$(command -v zsh)" ]; then
    version="$(zsh --version | awk '{print $2}')"
    echo "zsh is installed. required version: $ZSH_VERSION. now version: $version"

    [ "$version" = "$ZSH_VERSION" ] && is_installed=true
fi

# zshのインストール
if ! $is_installed; then
    sudo apt install -y wget tar make
    wget https://sourceforge.net/projects/zsh/files/zsh/$ZSH_VERSION/zsh-$ZSH_VERSION.tar.xz/download -O zsh-$ZSH_VERSION.tar.xz
    tar xvf zsh-$ZSH_VERSION.tar.xz -C ~/
    rm zsh-$ZSH_VERSION.tar.xz
    mv ~/zsh-$ZSH_VERSION ~/.zsh-install
    cd ~/.zsh-install
    ./configure --enable-multibyte
    make && sudo make install && rm -rf ~/.zsh-install
fi

# /etc/shellsに含まれていない場合は追加
if [ -z "$(cat /etc/shells | grep $(which zsh))" ]; then
    echo "zsh is not listed in /etc/shells."

    sudo sh -c "echo $(which zsh) >> /etc/shells"
else
    echo "zsh is listed in /etc/shells."
fi

# zinitのインストール
if [ ! -d "$HOME/.zinit" ]; then
    echo "zinit is not installed in $HOME/.zinit."

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
else
    echo "zinit is installed in $HOME/.zinit."
fi
