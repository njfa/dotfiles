#!/bin/bash

set -eu

cargo binstall zellij

ZJSTATUS_URL="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
ZJSTATUS_DIR="$HOME/.local/share/zellij/plugins"
ZJSTATUS_PATH="$ZJSTATUS_DIR/zjstatus.wasm"

mkdir -p "$ZJSTATUS_DIR"

echo "Installing zjstatus..."
curl -fL -o "$ZJSTATUS_PATH" "$ZJSTATUS_URL"
echo "zjstatus installed: $ZJSTATUS_PATH"

LAYOUT_PATH="$HOME/.config/zellij/layouts/zjstatus.kdl"
if [ ! -e "$LAYOUT_PATH" ]; then
    echo "Warning: zjstatus layout not found at $LAYOUT_PATH"
    echo "Deploy dotfiles or copy .config/zellij/layouts/zjstatus.kdl to enable the layout."
fi
