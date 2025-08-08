#!/bin/bash

set -eu

PWD=$(
    cd $(dirname $0)
    pwd
)
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
aarch64 | arm64)
    ARCH_TYPE="arm64"
    ARCH_DEB="arm64"
    ;;
armv7l | armhf)
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
    find $DOTFILES_PATH -mindepth 1 -name ".*" | grep -vE "(.git|.history|.gitignore|.DS_Store|.wslconfig|.claude|.serena)" | xargs -I {} find {} -type f | sed -e "s|$DOTFILES_PATH/||g" | grep -v ".config/nvim"
}

exec_cmd() {
    printcmd $1

    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs)
        # アーキテクチャ情報を環境変数として設定
        export DOTFILES_ARCH=$ARCH
        export DOTFILES_ARCH_TYPE=$ARCH_TYPE
        export DOTFILES_ARCH_DEB=$ARCH_DEB

        # 標準出力と標準エラーをリアルタイムで整形表示
        $EXEC_CMD $EXEC_OPTS $1 2> >(while IFS= read -r line; do
            printf "  \033[31m│\033[m %s\n" "$line" 1>&2
        done) | while IFS= read -r line; do
            printf "  \033[90m│\033[m %s\n" "$line"
        done
    )
    result=${PIPESTATUS[0]}

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
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs)
        $SYMLINK_CMD $SYMLINK_OPTS $1 $2 1>/dev/null
    ) || {
        printf "  \033[31m│\033[m Failed to link %s\n" "$filename" 1>&2
        exit 1
    }
}

sudo_symlink_cmd() {
    printcmd sudo $SYMLINK_CMD $SYMLINK_OPTS $1 $2
    (
        export $(grep -v '\(^#\|CMD\)' $DOTENV | xargs)
        sudo $SYMLINK_CMD $SYMLINK_OPTS $1 $2 1>/dev/null
    ) || {
        failure $SYMLINK_CMD $SYMLINK_OPTS $1 $2
        exit 1
    }
    success $SYMLINK_CMD $SYMLINK_OPTS $1 $2
}

install() {
    scripts=${@:1}
    if [ $# -eq 0 ]; then
        # 引数なしの場合はinit/ディレクトリのスクリプトのみを対象とする
        scripts=$(find "$DOTFILES_PATH/etc/os/" -type f -name "*.sh" -not -name "dependencies.sh" \( -path "$DOTFILES_PATH/etc/os/${OS,,}/init/*" -o -path "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/*" \) 2>/dev/null | xargs -r basename -s .sh | sort | uniq)
    fi

    for script in $scripts; do
        # init/ディレクトリのスクリプトを確認
        TARGET_OS_VERSION_INIT="$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/${script}.sh"
        TARGET_OS_INIT="$DOTFILES_PATH/etc/os/${OS,,}/init/${script}.sh"
        TARGET_OS_ARCH_INIT="$DOTFILES_PATH/etc/os/${OS,,}/init/${script}-${ARCH_TYPE}.sh"
        TARGET_OS_VERSION_ARCH_INIT="$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/${script}-${ARCH_TYPE}.sh"

        # opt/ディレクトリのスクリプトを確認
        TARGET_OS_VERSION_OPT="$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt/${script}.sh"
        TARGET_OS_OPT="$DOTFILES_PATH/etc/os/${OS,,}/opt/${script}.sh"
        TARGET_OS_ARCH_OPT="$DOTFILES_PATH/etc/os/${OS,,}/opt/${script}-${ARCH_TYPE}.sh"
        TARGET_OS_VERSION_ARCH_OPT="$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt/${script}-${ARCH_TYPE}.sh"

        # アーキテクチャ固有のスクリプトを最優先、次にバージョン固有、最後に汎用スクリプト
        # init/を優先、次にopt/
        if [ -f "$TARGET_OS_VERSION_ARCH_INIT" ]; then
            exec_cmd $TARGET_OS_VERSION_ARCH_INIT
        elif [ -f "$TARGET_OS_ARCH_INIT" ]; then
            exec_cmd $TARGET_OS_ARCH_INIT
        elif [ -f "$TARGET_OS_VERSION_INIT" ]; then
            exec_cmd $TARGET_OS_VERSION_INIT
        elif [ -f "$TARGET_OS_INIT" ]; then
            exec_cmd $TARGET_OS_INIT
        elif [ -f "$TARGET_OS_VERSION_ARCH_OPT" ]; then
            exec_cmd $TARGET_OS_VERSION_ARCH_OPT
        elif [ -f "$TARGET_OS_ARCH_OPT" ]; then
            exec_cmd $TARGET_OS_ARCH_OPT
        elif [ -f "$TARGET_OS_VERSION_OPT" ]; then
            exec_cmd $TARGET_OS_VERSION_OPT
        elif [ -f "$TARGET_OS_OPT" ]; then
            exec_cmd $TARGET_OS_OPT
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
    printf "\033[36m\n╔═════════════════════════════════════════════════════════════════╗\033[m\n"
    printf "\033[36m║                      📋 Available Scripts                       ║\033[m\n"
    printf "\033[36m╚═════════════════════════════════════════════════════════════════╝\033[m\n"

    # 必須パッケージ (init scripts)
    printf "\n\033[33m┌─ Required Packages (init) ──────────────────────────────────────┐\033[m\n"

    # OS固有のinitスクリプト
    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}/init" ]; then
        for f in $(find $DOTFILES_PATH/etc/os/${OS,,}/init -type f -name "*.sh" | sort); do
            script_name=$(basename --suffix=.sh $f)
            # インストール状態をチェック
            check_installed_status "$script_name" "\033[33m"
        done
    fi

    # バージョン固有のinitスクリプト
    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init" ]; then
        for f in $(find $DOTFILES_PATH/etc/os/${OS,,}-${VER}/init -type f -name "*.sh" | sort); do
            script_name=$(basename --suffix=.sh $f)
            # 重複を避けるためにOS固有で既に表示されていないかチェック
            if [ ! -f "$DOTFILES_PATH/etc/os/${OS,,}/init/${script_name}.sh" ]; then
                check_installed_status "$script_name" "\033[33m"
            fi
        done
    fi
    printf "\033[33m└─────────────────────────────────────────────────────────────────┘\033[m\n"

    # オプショナルパッケージ (opt scripts)
    printf "\n\033[35m┌─ Optional Packages (opt) ───────────────────────────────────────┐\033[m\n"
    printf "\033[35m│\033[m\033[90m These require explicit installation: setup.sh init <name>       \033[35m│\033[m\n"
    printf "\033[35m├─────────────────────────────────────────────────────────────────┤\033[m\n"

    # OS固有のoptスクリプト
    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}/opt" ]; then
        for f in $(find $DOTFILES_PATH/etc/os/${OS,,}/opt -type f -name "*.sh" | sort); do
            script_name=$(basename --suffix=.sh $f)
            check_installed_status "$script_name" "\033[35m"
        done
    fi

    # バージョン固有のoptスクリプト
    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt" ]; then
        for f in $(find $DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt -type f -name "*.sh" | sort); do
            script_name=$(basename --suffix=.sh $f)
            # 重複を避けるためにOS固有で既に表示されていないかチェック
            if [ ! -f "$DOTFILES_PATH/etc/os/${OS,,}/opt/${script_name}.sh" ]; then
                check_installed_status "$script_name" "\033[35m"
            fi
        done
    fi
    printf "\033[35m└─────────────────────────────────────────────────────────────────┘\033[m\n"

    # Dotfiles
    printf "\n\033[32m┌─ Dotfiles ──────────────────────────────────────────────────────┐\033[m\n"

    # get_dotfiles()を一度だけ呼び出して結果を保存
    dotfiles_list=$(get_dotfiles)
    total_dotfiles=$(echo "$dotfiles_list" | wc -l)

    # 最初の5個を表示
    echo "$dotfiles_list" | head -5 | while IFS= read -r f; do
        if [ -L "$HOME/$f" ]; then
            printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" "$f"
        else
            printf "\033[32m│\033[m \033[90m○\033[m %-61s \033[32m│\033[m\n" "$f"
        fi
    done

    # dotfilesが5個以上ある場合
    if [ $total_dotfiles -gt 5 ]; then
        printf "\033[32m│\033[m \033[90m  ... and $((total_dotfiles - 5)) more files\033[m%37s    \033[32m│\033[m\n" ""
    fi
    printf "\033[32m└─────────────────────────────────────────────────────────────────┘\033[m\n"

    printf "\n\033[90mLegend: \033[32m✓\033[90m Installed  \033[90m○\033[90m Not installed\033[m\n"
}

# インストール状態をチェックして表示する関数
check_installed_status() {
    local script_name=$1
    local frame_color=${2:-"\033[90m"} # デフォルトは灰色
    local installed=false
    local status_icon="\033[90m○\033[m"

    # 例外的なケースのみ個別に定義
    case $script_name in
    golang)
        [ -n "$(command -v go)" ] && installed=true
        ;;
    rust)
        [ -n "$(command -v cargo)" ] && installed=true
        ;;
    neovim)
        [ -n "$(command -v nvim)" ] && installed=true
        ;;
    graphviz)
        [ -n "$(command -v dot)" ] && installed=true
        ;;
    typescript)
        [ -n "$(command -v tsc)" ] && installed=true
        ;;
    python)
        [ -n "$(command -v python3)" ] && installed=true
        ;;
    postgresql)
        [ -n "$(command -v psql)" ] && installed=true
        ;;
    sdkman)
        [ -d "$HOME/.sdkman" ] && installed=true
        ;;
    font)
        # fonts-noto-cjk と fonts-noto-cjk-extra がインストールされているかチェック
        if dpkg -l | grep -q "fonts-noto-cjk " && dpkg -l | grep -q "fonts-noto-cjk-extra "; then
            installed=true
        fi
        ;;
    dependencies)
        # dependenciesは常に表示しない
        return
        ;;
    *)
        # デフォルト: スクリプト名と同じコマンドをチェック
        [ -n "$(command -v $script_name)" ] && installed=true
        ;;
    esac

    if [ "$installed" = true ]; then
        status_icon="\033[32m✓\033[m"
    fi

    printf "%b│%b %b %-61s %b│%b
" "$frame_color" "\033[m" "$status_icon" "$script_name" "$frame_color" "\033[m"
}

sync() {
    header "🔄 Starting WSL to Windows sync..."
    printf "[90m────────────────────────────────────────[m
"

    # Windows側のホームディレクトリを特定
    WINDOWS_HOME="/mnt/c/Users/$USER"
    if [ ! -d "$WINDOWS_HOME" ]; then
        # USERPROFILE環境変数から取得を試行
        if [ -n "$USERPROFILE" ]; then
            WINDOWS_HOME=$(echo "$USERPROFILE" | sed 's|\|/|g' | sed 's|^C:|/mnt/c|')
        else
            error "Windows home directory not found. Please ensure you are running in WSL."
            exit 1
        fi
    fi

    printf "
[36m📁 Syncing .dotfiles directory to Windows ($WINDOWS_HOME)...[m
"

    # .dotfilesディレクトリの名前を取得
    DOTFILES_DIR_NAME=$(basename "$DOTFILES_PATH")
    TARGET_DIR="$WINDOWS_HOME/$DOTFILES_DIR_NAME"

    # 既存の.dotfilesディレクトリがある場合は削除
    if [ -d "$TARGET_DIR" ]; then
        printf "  [90m│[m Removing existing $DOTFILES_DIR_NAME directory...
"
        rm -rf "$TARGET_DIR"
    fi

    # .dotfilesディレクトリを丸ごとコピー（.gitディレクトリを除外）
    printf "  [90m│[m Copying $DOTFILES_DIR_NAME directory...
"
    if rsync -av --exclude='.git' "$DOTFILES_PATH/" "$TARGET_DIR/" 2>/dev/null; then
        printf "  [90m│[m [32m✓[m Successfully synced $DOTFILES_DIR_NAME directory
"

        # コピーされたファイル数を表示
        file_count=$(find "$TARGET_DIR" -type f | wc -l)
        printf "  [90m│[m [90m  → $file_count files copied[m
"
    else
        printf "  [90m│[m [31m✗[m Failed to sync $DOTFILES_DIR_NAME directory
"
        exit 1
    fi

    printf "
[90m────────────────────────────────────────[m
"
    printf "[32m✨ Sync completed![m
"
    printf "[90mNote: $DOTFILES_DIR_NAME directory is now an independent copy at:[m
"
    printf "[90m      $TARGET_DIR[m
"
    printf "[90mRe-run 'sync' after making changes to WSL files.[m
"
}

deploy() {
    header "🔗 Starting dotfiles deployment..."
    printf "\033[90m────────────────────────────────────────\033[m\n"

    printf "\n\033[36m📁 Creating symbolic links...\033[m\n"
    for f in $(get_dotfiles); do
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

        # まずディレクトリ構造を作成
        if [ ! -d "$HOME/.claude" ]; then
            mkdir -p "$HOME/.claude"
            printf "  \033[90m│\033[m Created ~/.claude directory\n"
        fi

        # サブディレクトリを先に作成
        for f in $DOTFILES_PATH/.claude/*/; do
            if [ -d "$f" ]; then
                subdir_name=$(basename "$f")
                if [ ! -d "$HOME/.claude/$subdir_name" ]; then
                    mkdir -p "$HOME/.claude/$subdir_name"
                    printf "  \033[90m│\033[m Created ~/.claude/$subdir_name directory\n"
                fi
            fi
        done

        # その後ファイルとディレクトリの内容を配置
        for f in $DOTFILES_PATH/.claude/*; do
            if [ -d "$f" ]; then
                # ディレクトリの場合は内容をコピー
                cp -rf "$f" "$HOME/.claude/"
                printf "  \033[90m│\033[m Copied $(basename $f) directory contents\n"
            else
                # ファイルの場合はコピー
                cp "$f" "$HOME/.claude/"
                printf "  \033[90m│\033[m Copied $(basename $f) file\n"
            fi
        done
    fi

    # Claude Code設定ファイルの初期化
    printf "\n\033[36m🤖 Initializing Claude Code configuration...\033[m\n"
    if [ ! -f "$HOME/.claude.json" ]; then
        printf "  \033[90m│\033[m Creating ~/.claude.json\n"
        echo '{}' >"$HOME/.claude.json"
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
    sync        Sync WSL dotfiles to Windows (hard copy).
    list        List information about dotfiles.
"""
elif [ "$1" = "deploy" -o "$1" = "d" ]; then
    deploy
elif [ "$1" = "sync" -o "$1" = "s" ]; then
    sync
elif [ "$1" = "init" -o "$1" = "i" ]; then
    TARGET="${@:2}"
    initialize $TARGET
elif [ "$1" = "list" -o "$1" = "l" ]; then
    list
fi
