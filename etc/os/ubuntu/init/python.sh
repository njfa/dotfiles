#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

if [ -z "${PYTHON_VERSION:-}" ] && [ -f "$REPO_ROOT/.env" ]; then
    PYTHON_VERSION=$(awk -F= '$1=="PYTHON_VERSION"{val=$2} END{print val}' "$REPO_ROOT/.env")
    PYTHON_VERSION=$(printf '%s' "${PYTHON_VERSION:-}" | tr -d '"[:space:]')
fi

if [ -z "${PYTHON_VERSION:-}" ]; then
    echo "PYTHON_VERSION is not set. Export it or add it to $REPO_ROOT/.env." >&2
    exit 1
fi

if ! [[ "$PYTHON_VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Invalid PYTHON_VERSION \"$PYTHON_VERSION\". Use a value like 3.11 or 3.11.6." >&2
    exit 1
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if ! command -v pyenv >/dev/null 2>&1; then
    if [ ! -d "$PYENV_ROOT" ]; then
        git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
    fi
fi

if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
else
    echo "pyenv installation failed. Check $PYENV_ROOT." >&2
    exit 1
fi

if pyenv prefix "$PYTHON_VERSION" >/dev/null 2>&1; then
    install_needed=false
else
    install_needed=true
fi

if $install_needed; then
    # dependencies
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    pyenv install -s "$PYTHON_VERSION"
fi

pyenv global "$PYTHON_VERSION"

# uvのインストール
if ! command -v uv &>/dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # パスを通す（現在のセッション用）
    export PATH="$HOME/.local/bin:$PATH"
fi

# 確認
python --version || exit 1
pip --version || exit 1
