#!/bin/bash

if [ -z "$(command -v cargo)" ]; then
    curl https://sh.rustup.rs -sSf | xargs -0 -I {} sh -c {} rustup -y
fi

if [ ! -z "$(command -v fish)" -a -z "$(fish -c 'echo $fish_user_paths' | grep .cargo)" ]; then
    fish -c 'set -Ux fish_user_paths $HOME/.cargo/bin $fish_user_paths'
fi