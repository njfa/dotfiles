#!/bin/bash

TMUX_PATH=~/.tmux

if [ ! -d "$TMUX_PATH" ]; then
    sudo apt install -y git automake bison build-essential pkg-config libevent-dev libncurses5-dev

    git clone https://github.com/tmux/tmux $TMUX_PATH

    cd $TMUX_PATH
    ./autogen.sh
    ./configure --prefix=/usr/local
    make
    sudo make install
    tmux -V
fi

if [ ! -z "$USERPROFILE" -a -z "$(command -v win32yank.exe)" ]; then
    sudo apt install -y zip
    curl -LO https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
    unzip -d $(wslpath -u "$USERPROFILE/bin") win32yank-x64.zip
    rm win32yank-x64.zip
fi