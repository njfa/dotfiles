#!/bin/bash

eval "PYTHON_VERSION=$PYTHON_VERSION"

# uvのインストール
if ! command -v uv &>/dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # パスを通す（現在のセッション用）
    export PATH="$HOME/.local/bin:$PATH"
fi

# uvでPythonをインストール
if ! uv python list --only-installed | grep -q "${PYTHON_VERSION}"; then
    echo "Installing Python ${PYTHON_VERSION}..."
    uv python install ${PYTHON_VERSION}
fi

# 仮想環境のベースパス
VENV_BASE="$HOME/.local/python-env"
VENV_PATH="${VENV_BASE}/${PYTHON_VERSION}"
VENV_GLOBAL="${VENV_BASE}/global"

# ディレクトリが存在しない場合は作成
mkdir -p "${VENV_BASE}"

# バージョン別の仮想環境の作成（既存の場合はスキップ）
if [ ! -d "${VENV_PATH}" ]; then
    echo "Creating virtual environment at ${VENV_PATH}..."
    uv venv --system-site-packages "${VENV_PATH}"
fi

# globalシンボリックリンクの更新
if [ -L "${VENV_GLOBAL}" ]; then
    rm "${VENV_GLOBAL}"
fi
ln -s "${VENV_PATH}" "${VENV_GLOBAL}"
echo "Updated global link to Python ${PYTHON_VERSION}"

# 仮想環境をアクティベート（globalを使用）
export PATH="${VENV_GLOBAL}/bin:$PATH"
export VIRTUAL_ENV="${VENV_GLOBAL}"

# 必要なパッケージをインストール
echo "Installing Python packages..."
uv pip install --python "${VENV_PATH}" pip yq tomlq

# 確認
python --version || exit 1
pip --version || exit 1
