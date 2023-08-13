#!/bin/sh

is_installed=false

if [ -n "$(command -v delta)" ]; then
    version="$(delta --version | awk '{print $2}')"
    echo "delta is installed. required version: $DELTA_VERSION. now version: $version"

    [ "$version" = "$DELTA_VERSION" ] && is_installed=true
else
    echo "delta is not installed. required version: $DELTA_VERSION."
fi


# deltaのインストール
if ! $is_installed; then
    arch=$(dpkg --print-architecture)
    curl -Lo git-delta.deb "https://github.com/dandavison/delta/releases/download/$DELTA_VERSION/git-delta_$DELTA_VERSION_$arch.deb"
    sudo dpkg -i git-delta.deb
    rm git-delta.deb
fi

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

if [ -n "$(command -v zsh)" ]; then
    echo "Please exec \`sed -i \"s|'delta'.*|'delta' '_delta'|g\" ~/.zcompdump && autoload -Uz compinit && compinit\`"
fi
