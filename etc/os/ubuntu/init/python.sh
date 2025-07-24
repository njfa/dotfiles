#!/bin/bash

eval "PYTHON_VERSION=$PYTHON_VERSION"

export UV_CACHE_DIR="$HOME/.cache/uv"
export PATH="$HOME/.local/bin:$PATH"

# uvのインストール
if [ -z "$(command -v uv)" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# 指定されたPythonバージョンをインストール
if ! uv python list --only-installed | grep -q "$PYTHON_VERSION"; then
    uv python install "$PYTHON_VERSION"
fi

# PythonバージョンをPINして使用可能にする
uv python pin "$PYTHON_VERSION"

# pythonコマンドのシンボリックリンクを作成
PYTHON_PATH=$(uv python find "$PYTHON_VERSION")
if [ -n "$PYTHON_PATH" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$PYTHON_PATH" "$HOME/.local/bin/python"
fi

# Python環境の確認
python --version || exit 1
uv pip list || exit 1
