#!/bin/bash

# fontforgeのインストール
if [ -z "$(command -v fontforge)" ]; then
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:fontforge/fontforge
    sudo apt update -y
    sudo apt install -y fontforge python-fontforge
fi