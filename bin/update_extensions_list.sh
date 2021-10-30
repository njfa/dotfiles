#!/bin/bash

set -eu

PWD=$(cd $(dirname $0); pwd)
DOTFILES_PATH=$(dirname $PWD)
VSCODE_PATH=$DOTFILES_PATH/etc/os/windows/vscode

code --list-extensions > $VSCODE_PATH/extensions