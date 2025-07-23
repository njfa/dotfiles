#!/bin/bash

# uvとPython環境のセットアップ
export UV_CACHE_DIR="$HOME/.cache/uv"
export PATH="$HOME/.local/bin:$PATH"

# Pythonの警告を抑制
export PYTHONWARNINGS="ignore::BrokenPipeError"

if command -v uv >/dev/null 2>&1 && uv pip list --system >/dev/null 2>&1; then
    echo "uv pip is available."
else
    echo "uv pip is not available. Setting up Python environment..."
    PWD=$(
        cd $(dirname $0)
        pwd
    )
    sh $PWD/python.sh
fi

if uv pip list --system 2>/dev/null | grep -q "pynvim" 2>/dev/null; then
    echo "pynvim is installed."
else
    echo "pynvim is not installed."
    uv pip install --system --break-system-packages pynvim
fi

if uv pip list --system 2>/dev/null | grep -q "neovim-remote" 2>/dev/null; then
    echo "neovim-remote is installed."
else
    echo "neovim-remote is not installed."
    uv pip install --system --break-system-packages neovim-remote
fi

# nvrコマンドへのシンボリックリンクを作成
mkdir -p "$HOME/.local/bin"
PYTHON_SCRIPTS_DIR=$(python -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>/dev/null)
if [ -n "$PYTHON_SCRIPTS_DIR" ] && [ -f "$PYTHON_SCRIPTS_DIR/nvr" ]; then
    ln -sf "$PYTHON_SCRIPTS_DIR/nvr" "$HOME/.local/bin/nvr"
    echo "nvr command linked to ~/.local/bin/nvr"
elif python -m nvr --version >/dev/null 2>&1; then
    # nvr が python -m nvr として実行可能な場合、ラッパースクリプトを作成
    cat >"$HOME/.local/bin/nvr" <<'EOF'
#!/bin/bash
exec python -m nvr "$@"
EOF
    chmod +x "$HOME/.local/bin/nvr"
    echo "nvr wrapper script created at ~/.local/bin/nvr"
fi

if command -v rg >/dev/null 2>&1; then
    echo "ripgrep is installed."
else
    echo "ripgrep is not installed."
    sudo apt install -y ripgrep
fi

if command -v fdfind >/dev/null 2>&1; then
    echo "fd-find is installed."
else
    echo "fd-find is not installed."
    sudo apt install -y fd-find
fi

is_installed=false

# ダウンロード先のディレクトリを生成
[ ! -d "$HOME/.nvim" ] && mkdir ~/.nvim

if command -v nvim >/dev/null 2>&1; then
    version="$(nvim --version | grep "NVIM" | awk '{print $2}')"
    echo "neovim is installed. required version: $NEOVIM_VERSION. now version: $version"

    [ "$version" = "$NEOVIM_VERSION" ] && is_installed=true
else
    echo "neovim is not installed. required version: $NEOVIM_VERSION."
fi

if ! $is_installed; then
    if [ ! -d "$HOME/.nvim/$NEOVIM_VERSION" ]; then
        echo "neovim is not downloaded."

        # CPUアーキテクチャを検出
        arch=$(uname -m)
        case "$arch" in
        x86_64)
            arch_suffix="linux-x86_64"
            ;;
        aarch64 | arm64)
            arch_suffix="linux-arm64"
            ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
        esac

        # バージョンによってファイル名を決定
        # 新しいバージョンでは nvim-{arch}.appimage、古いバージョンでは nvim.appimage
        appimage_filename="nvim-${arch_suffix}.appimage"
        download_url="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${appimage_filename}"

        # 新しいファイル名でダウンロードを試みる
        echo "Detected architecture: $arch"
        echo "Trying to download: ${download_url}"
        if ! curl -fLo nvim.appimage "$download_url"; then
            echo "Failed to download ${appimage_filename}, trying legacy filename..."
            # 古いファイル名で再試行（アーキテクチャ非依存）
            appimage_filename="nvim.appimage"
            download_url="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/${appimage_filename}"
            echo "Trying to download: ${download_url}"
            if ! curl -fLo nvim.appimage "$download_url"; then
                echo "Error: Failed to download Neovim AppImage from both URLs"
                echo "Please check if version ${NEOVIM_VERSION} exists and supports your architecture"
                exit 1
            fi
        fi

        chmod u+x nvim.appimage && ./nvim.appimage --appimage-extract
        mv squashfs-root ~/.nvim/$NEOVIM_VERSION
        rm nvim.appimage
    else
        echo "neovim is already downloaded."
    fi

    sudo ln -sf ~/.nvim/$NEOVIM_VERSION/usr/bin/nvim /usr/local/bin/nvim
    rm -rf ~/.config/nvim/plugin/packer_compiled.lua ~/.local/share/nvim
fi
