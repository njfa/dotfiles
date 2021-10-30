#!/bin/bash

if [ -z "$(command -v cargo)" ]; then
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/rust.sh
    source $HOME/.cargo/env
fi

cargo install ripgrep exa bat tokei lsd fselect navi xsv csview hexyl bingrep