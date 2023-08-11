#!/bin/bash

arch=$(dpkg --print-architecture)
curl -Lo git-delta.deb "https://github.com/dandavison/delta/releases/download/0.16.5/git-delta_0.16.5_$arch.deb"
sudo dpkg -i git-delta.deb
rm git-delta.deb

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
