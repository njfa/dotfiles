#!/bin/bash

if ! cargo version 2>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

cargo install ripgrep bat tokei sqlx-cli
