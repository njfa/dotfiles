#!/bin/bash

set -eu

PWD=$(cd $(dirname $0); pwd)
DOTFILES_PATH=$(dirname $PWD)
DOTENV=$DOTFILES_PATH/.env

export $(grep -v '^#' $DOTENV | xargs)

# アーキテクチャ検出
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH_TYPE="x64"
        ARCH_DEB="amd64"
        ;;
    aarch64|arm64)
        ARCH_TYPE="arm64"
        ARCH_DEB="arm64"
        ;;
    armv7l|armhf)
        ARCH_TYPE="arm"
        ARCH_DEB="armhf"
        ;;
    *)
        ARCH_TYPE="unknown"
        ARCH_DEB="unknown"
        ;;
esac

echo "Detected architecture: $ARCH_TYPE ($ARCH)"

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
Architecture: $ARCH_TYPE
\033[m\n"
}

header() {
    printf "\033[37;1m%s\033[m \n" "$*"
}

item() {
    printf "    \033[37;1m%s\033[m%s \n" "- " "$*"
}

printcmd() {
    # スクリプト名のみを抽出
    script_name=$(basename $1 .sh)
    printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "$script_name"
}

success() {
    # スクリプト名のみを抽出
    script_name=$(basename $1 .sh)
    printf "\033[32;1m[✓]\033[m %s completed successfully\n" "$script_name"
}

failure() {
    # スクリプト名のみを抽出
    script_name=$(basename $1 .sh)
    printf "\033[31;1m[✗]\033[m %s failed\n" "$script_name" 1>&2
}

error() {
    printf "\n\033[31;1m%s\033[m \n" "$*" 1>&2
}

get_dotfiles() {
    find $DOTFILES_PATH -mindepth 1 -name ".*" | grep -vE "(.git|.history|.gitignore|.DS_Store|.wslconfig|.claude)" | xargs -I {} find {} -type f | sed -e "s|$DOTFILES_PATH/||g" | grep -v ".config/nvim"
}

exec_cmd() {
    printcmd $1

    # スクリプトの出力を一時ファイルに保存
    output_file=$(mktemp)
    error_file=$(mktemp)

    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs)
        # アーキテクチャ情報を環境変数として設定
        export DOTFILES_ARCH=$ARCH
        export DOTFILES_ARCH_TYPE=$ARCH_TYPE
        export DOTFILES_ARCH_DEB=$ARCH_DEB
        $EXEC_CMD $EXEC_OPTS $1 > "$output_file" 2> "$error_file"
    )
    result=$?

    # 出力内容を整形して表示
    if [ -s "$output_file" ]; then
        while IFS= read -r line; do
            printf "  \033[90m│\033[m %s\n" "$line"
        done < "$output_file"
    fi

    # エラー出力がある場合は表示
    if [ -s "$error_file" ]; then
        while IFS= read -r line; do
            printf "  \033[31m│\033[m %s\n" "$line" 1>&2
        done < "$error_file"
    fi

    # 一時ファイルを削除
    rm -f "$output_file" "$error_file"

    if [ $result -eq 0 ]; then
        success $1
    else
        failure $1
        sudo apt --fix-broken install -y
        exit 1
    fi
}

symlink_cmd() {
    # シンボリックリンク作成時は簡潔な表示
    filename=$(basename $1)
    printf "  \033[90m│\033[m Linking %s\n" "$filename"
    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs); $SYMLINK_CMD $SYMLINK_OPTS $1 $2 1>/dev/null
    ) || {
        printf "  \033[31m│\033[m Failed to link %s\n" "$filename" 1>&2
        exit 1
    }
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
        TARGET_OS_ARCH="$DOTFILES_PATH/etc/os/${OS,,}/init/${script}-${ARCH_TYPE}.sh"
        TARGET_OS_VERSION_ARCH="$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/${script}-${ARCH_TYPE}.sh"

        # アーキテクチャ固有のスクリプトを最優先、次にバージョン固有、最後に汎用スクリプト
        if [ -f "$TARGET_OS_VERSION_ARCH" ]; then
            exec_cmd $TARGET_OS_VERSION_ARCH
        elif [ -f "$TARGET_OS_ARCH" ]; then
            exec_cmd $TARGET_OS_ARCH
        elif [ -f "$TARGET_OS_VERSION" ]; then
            exec_cmd $TARGET_OS_VERSION
        elif [ -f "$TARGET_OS" ]; then
            exec_cmd $TARGET_OS
        fi
    done
}

initialize() {
    header "🚀 Starting initialization process..."
    printf "\033[90m────────────────────────────────────────\033[m\n"

    # ARM64環境で特別な処理が必要な場合の準備
    if [ "$ARCH_TYPE" = "arm64" ]; then
        printf "\033[93m⚡ ARM64 architecture detected\033[m\n"
        # ARM64用のパッケージソースを追加する等の処理
        export ARCH_TYPE
        export ARCH_DEB
    fi

    # 必須の依存パッケージをインストール
    printf "\n\033[36m📦 Installing dependencies...\033[m\n"
    install dependencies

    # 指定のパッケージをインストール
    if [ $# -gt 0 ]; then
        printf "\n\033[36m📦 Installing selected packages...\033[m\n"
        install ${@:1}
    else
        printf "\n\033[36m📦 Installing all packages...\033[m\n"
        install
    fi

    printf "\n\033[90m────────────────────────────────────────\033[m\n"
    printf "\033[32m✨ Initialization completed!\033[m\n"
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
    header "🔗 Starting dotfiles deployment..."
    printf "\033[90m────────────────────────────────────────\033[m\n"

    printf "\n\033[36m📁 Creating symbolic links...\033[m\n"
    for f in $(get_dotfiles)
    do
        if [ ! -d $(dirname "$HOME/$f") ]; then
            mkdir -p $(dirname "$HOME/$f")
        fi
        symlink_cmd "$DOTFILES_PATH/$f" "$HOME/$f"
    done

    if [ -d "$DOTFILES_PATH/.config/nvim" -a ! -e "$HOME/.config/nvim" ]; then
        printf "\n\033[36m📝 Linking Neovim configuration...\033[m\n"
        symlink_cmd $DOTFILES_PATH/.config/nvim $HOME/.config/nvim
    fi

    if [ -d "$DOTFILES_PATH/.claude" ]; then
        printf "\n\033[36m🤖 Setting up Claude configuration...\033[m\n"
        if [ ! -d "$HOME/.claude" ]; then
            mkdir -p "$HOME/.claude"
        fi
        for f in $DOTFILES_PATH/.claude/*; do
            if [ -d "$f" ]; then
                # ディレクトリの場合はコピーを作成
                cp -rf "$f" "$HOME/.claude/$(basename $f)"
            else
                # ファイルの場合はコピー
                cp "$f" "$HOME/.claude/"
            fi
            printf "  \033[90m│\033[m Copied $(basename $f)\n"
        done
    fi

    # Claude Code設定ファイルの初期化
    printf "\n\033[36m🤖 Initializing Claude Code configuration...\033[m\n"
    if [ ! -f "$HOME/.claude.json" ]; then
        printf "  \033[90m│\033[m Creating ~/.claude.json\n"
        echo '{}' > "$HOME/.claude.json"
        printf "  \033[90m│\033[m ~/.claude.json created\n"
    else
        printf "  \033[90m│\033[m ~/.claude.json already exists\n"
    fi

    if [ -f "$DOTFILES_PATH/wsl.conf" ]; then
        printf "\n\033[36m🐧 Configuring WSL...\033[m\n"
        if [ ! -z "$(command -v sudo)" ]; then
            sudo cp $DOTFILES_PATH/wsl.conf /etc/wsl.conf
            printf "  \033[90m│\033[m WSL configuration updated\n"
        elif [ "$UID" -eq 0 ]; then
            cp $DOTFILES_PATH/wsl.conf /etc/wsl.conf
            printf "  \033[90m│\033[m WSL configuration updated\n"
        fi
    fi

    printf "\n\033[36m⚙️  Configuring Git...\033[m\n"
    git config --global core.editor "vim"
    git config --global core.autoCRLF false
    printf "  \033[90m│\033[m Git configuration updated\n"

    printf "\n\033[90m────────────────────────────────────────\033[m\n"
    printf "\033[32m✨ Deployment completed!\033[m\n"
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
