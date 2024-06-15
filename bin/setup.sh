#!/bin/bash

set -eu

PWD=$(cd $(dirname $0); pwd)
DOTFILES_PATH=$(dirname $PWD)
DOTENV=$DOTFILES_PATH/.env

export $(grep -v '^#' $DOTENV | xargs)

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

title() {
    printf '\033[37;1m
                       __                         
                      /  |                        
  _______   ______   _$$ |_    __    __   ______  
 /       | /      \ / $$   |  /  |  /  | /      \ 
/$$$$$$$/ /$$$$$$  |$$$$$$/   $$ |  $$ |/$$$$$$  |
$$      \ $$    $$ |  $$ | __ $$ |  $$ |$$ |  $$ |
 $$$$$$  |$$$$$$$$/   $$ |/  |$$ \__$$ |$$ |__$$ |
/     $$/ $$       |  $$  $$/ $$    $$/ $$    $$/ 
$$$$$$$/   $$$$$$$/    $$$$/   $$$$$$/  $$$$$$$/  
                                        $$ |      
                                        $$ |      
                                        $$/       
\n\033[m'

    printf "\033[37;1m
OS: $OS
Version: $VER
\033[m\n"
}

header() {
    printf "\033[37;1m%s\033[m \n" "$*"
}

item() {
    printf "    \033[37;1m%s\033[m%s \n" "- " "$*"
}

printcmd() {
    printf "  \033[34;1m%s\033[m\`%s\`\n" "Execute " "$*"
}

success() {
    printf "    \033[32;1m%s\033[m\`%s\` is success \n" "✓ " "$*"
}

failure() {
    printf "    \033[31;1m%s\033[m\`%s\` is failure \n" "✗ " "$*" 1>&2
}

error() {
    printf "\n\033[31;1m%s\033[m \n" "$*" 1>&2
}

get_dotfiles() {
    find $DOTFILES_PATH -mindepth 1 -name ".*" | grep -vE "(.git|.history|.gitignore|.DS_Store|.wslconfig)" | xargs -I {} find {} -type f | sed -e "s|$DOTFILES_PATH/||g" | grep -v ".config/nvim"
}

exec_cmd() {
    printcmd $EXEC_CMD $EXEC_OPTS $1
    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs); $EXEC_CMD $EXEC_OPTS $1
    ) || {
        failure $EXEC_CMD $EXEC_OPTS $1
        sudo apt --fix-broken install -y
        exit 1
    }
    success $EXEC_CMD $EXEC_OPTS $1
}

symlink_cmd() {
    printcmd $SYMLINK_CMD $SYMLINK_OPTS $1 $2
    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs); $SYMLINK_CMD $SYMLINK_OPTS $1 $2 1>/dev/null
    ) || {
        failure $SYMLINK_CMD $SYMLINK_OPTS $1 $2
        exit 1
    }
    success $SYMLINK_CMD $SYMLINK_OPTS $1 $2
}

sudo_symlink_cmd() {
    printcmd sudo $SYMLINK_CMD $SYMLINK_OPTS $1 $2
    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs); sudo $SYMLINK_CMD $SYMLINK_OPTS $1 $2 1>/dev/null
    ) || {
        failure $SYMLINK_CMD $SYMLINK_OPTS $1 $2
        exit 1
    }
    success $SYMLINK_CMD $SYMLINK_OPTS $1 $2
}

install() {
    scripts=${@:1}
    if [ $# -eq 0 ]; then
        # 全スクリプトの一覧を作成する
        scripts=$(find "$DOTFILES_PATH/etc/os/" -type f -name "*.sh" -not -name "dependencies.sh" -path "$DOTFILES_PATH/etc/os/${OS,,}/*" -o -path "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/*" | xargs basename -s .sh | sort | uniq)
    fi

    for script in $scripts; do
        TARGET_OS_VERSION="$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/${script}.sh"
        TARGET_OS="$DOTFILES_PATH/etc/os/${OS,,}/init/${script}.sh"

        # バージョンが明示されたディレクトリのスクリプトを優先して適用する
        if [ -f "$TARGET_OS_VERSION" ]; then
            exec_cmd $TARGET_OS_VERSION
        elif [ -f "$TARGET_OS" ]; then
            exec_cmd $TARGET_OS
        fi
    done
}

initialize() {
    header "Start initializing dotfiles ..."

    # 必須の依存パッケージをインストール
    install dependencies

    # 指定のパッケージをインストール
    install ${@:1}
}

list() {
    header "list:"

    header "  init scripts (${OS,,}):"
    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}/init" ]; then
        for f in `find $DOTFILES_PATH/etc/os/${OS,,}/init -type f -name "*.sh"`
        do
            item $(basename --suffix=.sh $f)
        done
    fi

    header "  init scripts (${OS,,}-${VER}):"
    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init" ]; then
        for f in `find $DOTFILES_PATH/etc/os/${OS,,}-${VER}/init -type f -name "*.sh"`
        do
            item $(basename --suffix=.sh $f)
        done
    fi

    header "  dotfiles:"
    for f in $(get_dotfiles)
    do
        item "$f"
    done
}

deploy() {

    header "Start deploying dotfiles ..."
    for f in $(get_dotfiles)
    do
        if [ ! -d $(dirname "$HOME/$f") ]; then
            mkdir -p $(dirname "$HOME/$f")
        fi
        symlink_cmd "$DOTFILES_PATH/$f" "$HOME/$f"
    done

    if [ -d "$DOTFILES_PATH/.config/nvim" ]; then
        symlink_cmd $DOTFILES_PATH/.config/nvim $HOME/.config/nvim
    fi

    if [ -f "$DOTFILES_PATH/wsl.conf" ]; then
        if [ ! -z "$(command -v sudo)" ]; then
            sudo_symlink_cmd $DOTFILES_PATH/wsl.conf /etc/wsl.conf
        elif [ "$UID" -eq 0 ]; then
            symlink_cmd $DOTFILES_PATH/wsl.conf /etc/wsl.conf
        fi
    fi

    header "Update git config"
    git config --global core.editor "vim"
    git config --global core.autoCRLF false
}

title

if [ $# -eq 0 ]; then
    echo """Usage: setup.sh [command]

Commands:
    init        Initialize commands.
    deploy      Deploy dotfiles.
    list        List information about dotfiles.
"""
elif [ "$1" = "deploy" -o "$1" = "d" ]; then
    deploy
elif [ "$1" = "init" -o "$1" = "i" ]; then
    TARGET="${@:2}"
    initialize $TARGET
elif [ "$1" = "list" -o "$1" = "l" ]; then
    list
fi
