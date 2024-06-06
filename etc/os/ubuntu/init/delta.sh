#!/bin/sh

is_installed=false

if command -v delta >/dev/null 2>&1; then
    version="$(delta --version | awk '{print $2}')"
    echo "delta is installed. required version: $DELTA_VERSION. now version: $version"

    [ "$version" = "$DELTA_VERSION" ] && is_installed=true
else
    echo "delta is not installed. required version: $DELTA_VERSION."
fi

# deltaのインストール
if ! $is_installed; then
    arch=$(dpkg --print-architecture)
    curl -Lo git-delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${arch}.deb"

    if sudo dpkg -i git-delta.deb && rm git-delta.deb; then
        echo "git config"
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.side-by-side true
        git config --global delta.line-numbers true
        git config --global delta.navigate true
        git config --global delta.light false
        git config --global delta.true-color always
        git config --global delta.syntax-theme Dracula
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
    else
        exit 1
    fi
fi
