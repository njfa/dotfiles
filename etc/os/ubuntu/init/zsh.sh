#!/bin/sh

is_installed=false
zsh_required_version="${ZSH_VERSION:-}"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Skipping zsh: sudo is unavailable and current user is not root." >&2
    exit 0
fi

if [ -n "$(command -v zsh)" ]; then
    version="$(zsh --version | awk '{print $2}')"
    if [ -n "$zsh_required_version" ]; then
        echo "zsh is installed. required version: $zsh_required_version. now version: $version"
        [ "$version" = "$zsh_required_version" ] && is_installed=true
    else
        echo "zsh is installed. now version: $version"
        is_installed=true
    fi
else
    if [ -n "$zsh_required_version" ]; then
        echo "zsh is not installed. required version: $zsh_required_version."
    else
        echo "zsh is not installed."
    fi
fi

# zshのインストール
if ! $is_installed; then
    # 未指定の場合は最新バージョンを取得
    if [ -z "$zsh_required_version" ]; then
        if ! command -v curl >/dev/null 2>&1; then
            $SUDO apt install -y curl
        fi
        zsh_required_version="$(curl -fsSL https://www.zsh.org/pub/ | grep -o 'zsh-[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -n1 | sed 's/zsh-//')"
        if [ -z "$zsh_required_version" ]; then
            echo "failed to resolve latest zsh version."
            exit 1
        fi
    fi

    zsh_tarball_url="https://www.zsh.org/pub/zsh-$zsh_required_version.tar.xz"
    $SUDO apt install -y wget tar make
    wget "$zsh_tarball_url" -O zsh-$zsh_required_version.tar.xz
    tar xvf zsh-$zsh_required_version.tar.xz -C ~/
    rm zsh-$zsh_required_version.tar.xz
    mv ~/zsh-$zsh_required_version ~/.zsh-install
    cd ~/.zsh-install
    ./configure --enable-multibyte
    make && $SUDO make install && rm -rf ~/.zsh-install
fi

# /etc/shellsに含まれていない場合は追加
if [ -z "$(cat /etc/shells | grep $(which zsh))" ]; then
    echo "zsh is not listed in /etc/shells."

    $SUDO sh -c "echo $(which zsh) >> /etc/shells"
else
    echo "zsh is listed in /etc/shells."
fi

# zinitのインストール
if [ ! -d "$HOME/.zinit" ]; then
    echo "zinit is not installed in $HOME/.zinit."

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
else
    echo "zinit is installed in $HOME/.zinit."
fi
