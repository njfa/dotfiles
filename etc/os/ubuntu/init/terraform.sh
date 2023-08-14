#!/bin/sh

is_installed=false

if [ ! -d "$HOME/.tfenv" ]; then
    echo "tfenv is not installed."

    git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
else
    echo "tfenv is installed."
fi

