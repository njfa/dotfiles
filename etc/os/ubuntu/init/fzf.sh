#!/bin/bash

# fzfのインストール
if [ -z "$(command -v fzf)" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    yes | ~/.fzf/install
fi
