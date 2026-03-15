#!/bin/bash

set -euo pipefail

PWD=$(
    cd $(dirname $0)
    pwd
)
DOTFILES_PATH=$(dirname $PWD)
DOTENV=$DOTFILES_PATH/.env
MISE_CONFIG_PATH="$HOME/.config/mise/config.toml"

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

ensure_mise() {
    if command -v mise >/dev/null 2>&1; then
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            if ! command -v sudo >/dev/null 2>&1; then
                apt-get update -y
                apt-get install -y sudo
            fi
            sudo apt-get update -y
            sudo apt-get install -y curl
        else
            error "curl is required to install mise."
            exit 1
        fi
    fi

    curl -fsSL https://mise.jdx.dev/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    if [ -z "${MISE_CACHE_DIR:-}" ]; then
        export MISE_CACHE_DIR="/tmp/mise-cache"
    fi
    if [ -z "${MISE_DATA_DIR:-}" ]; then
        export MISE_DATA_DIR="/tmp/mise-data"
    fi
    # Ensure shims are available in this non-interactive shell
    eval "$(mise activate bash)"
}

mise_use_from_config() {
    if [ ! -f "$MISE_CONFIG_PATH" ]; then
        return
    fi

    mapfile -t tools < <(awk '
        /^\[tools\]/{f=1; next}
        /^\[/{f=0}
        f && /=/ {
            gsub(/#.*/, "", $0)
            split($0, a, "=")
            gsub(/[[:space:]]+/, "", a[1])
            gsub(/^"|"$/, "", a[1])
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[2])
            gsub(/^"|"$/, "", a[2])
            if (a[1] != "" && a[2] != "") print a[1] "@" a[2]
        }
    ' "$MISE_CONFIG_PATH")

    if [ ${#tools[@]} -gt 0 ]; then
        printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise use --global (config tools)"
        (
            cd "$HOME"
            mise use --global "${tools[@]}"
        )
        printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise use --global (config tools)"
    fi
}

ensure_mise_config_deployed() {
    if [ -f "$MISE_CONFIG_PATH" ]; then
        return
    fi

    printf "\n\033[36m📁 Mise config not found at %s. Running deploy...\033[m\n" "$MISE_CONFIG_PATH"
    deploy
}

mise_trust() {
    (
        cd "$DOTFILES_PATH"
        MISE_YES=1 mise trust
    )
}

get_dotfiles() {
    find $DOTFILES_PATH -mindepth 1 -name ".*" | grep -vE "(.git|.history|.gitignore|.DS_Store|.wslconfig|.codex|.gemini|.claude|.serena|.spec-workflow)" | xargs -I {} find {} -type f | sed -e "s|$DOTFILES_PATH/||g" | grep -vE ".config/(nvim|zellij)"
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

resolve_os_script() {
    local script="$1"
    local candidates=(
        "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/${script}-${ARCH_TYPE}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}/init/${script}-${ARCH_TYPE}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/${script}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}/init/${script}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt/${script}-${ARCH_TYPE}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}/opt/${script}-${ARCH_TYPE}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt/${script}.sh"
        "$DOTFILES_PATH/etc/os/${OS,,}/opt/${script}.sh"
    )

    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

install_os_scripts() {
    local scripts=("$@")

    if [ $# -eq 0 ]; then
        scripts=$(find "$DOTFILES_PATH/etc/os/" -type f -name "*.sh" -not -name "dependencies.sh" \( -path "$DOTFILES_PATH/etc/os/${OS,,}/init/*" -o -path "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/init/*" \) 2>/dev/null | xargs -r basename -s .sh | sort | uniq)
    fi

    for script in $scripts; do
        resolved_script=$(resolve_os_script "$script" || true)
        if [ -n "$resolved_script" ]; then
            exec_cmd "$resolved_script"
        fi
    done
}

install_os_optional() {
    local scripts=""

    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}/opt" ]; then
        scripts="$scripts $(find "$DOTFILES_PATH/etc/os/${OS,,}/opt" -type f -name "*.sh" 2>/dev/null | xargs -r basename -s .sh)"
    fi

    if [ -d "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt" ]; then
        scripts="$scripts $(find "$DOTFILES_PATH/etc/os/${OS,,}-${VER}/opt" -type f -name "*.sh" 2>/dev/null | xargs -r basename -s .sh)"
    fi

    if [ -n "$scripts" ]; then
        install_os_scripts $scripts
    fi
}

install() {
    local targets=("$@")
    local mise_tasks=("default" "optional" "delta-config" "rustup" "python-tools" "node-tools" "cargo-tools" "zjstatus" "zellij")
    local mise_tools=()
    local run_tasks=()
    local os_scripts=()
    local run_optional=false

    if [ ${#targets[@]} -eq 0 ]; then
        install_os_scripts dependencies
        install_os_scripts
        ensure_mise_config_deployed
        ensure_mise
        mise_trust
        mise_use_from_config
        printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise install"
        mise install
        printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise install"
        printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise run default"
        mise run default
        printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise run default"
        return
    fi

    for target in "${targets[@]}"; do
        if [ "$target" = "optional" ]; then
            run_optional=true
            run_tasks+=("$target")
            continue
        fi

        if printf '%s\n' "${mise_tasks[@]}" | grep -qx "$target"; then
            run_tasks+=("$target")
            continue
        fi

        if resolve_os_script "$target" >/dev/null 2>&1; then
            os_scripts+=("$target")
        else
            mise_tools+=("$target")
        fi
    done

    if $run_optional; then
        install_os_optional
    fi

    if [ ${#os_scripts[@]} -gt 0 ]; then
        install_os_scripts "${os_scripts[@]}"
    fi

    if [ ${#mise_tools[@]} -gt 0 ] || [ ${#run_tasks[@]} -gt 0 ]; then
        ensure_mise_config_deployed
        ensure_mise
        mise_trust
        mise_use_from_config
        printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise install"
        mise install
        printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise install"

        if [ ${#mise_tools[@]} -gt 0 ]; then
            printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise install ${mise_tools[*]}"
            mise install "${mise_tools[@]}"
            printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise install ${mise_tools[*]}"
            printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise use --global ${mise_tools[*]}"
            (
                cd "$HOME"
                mise use --global "${mise_tools[@]}"
            )
            printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise use --global ${mise_tools[*]}"
        fi

        if [ ${#run_tasks[@]} -gt 0 ]; then
            for task in "${run_tasks[@]}"; do
                printf "\n\033[34;1m[%s]\033[m %s\n" "RUN" "mise run ${task}"
                mise run "$task"
                printf "\033[32;1m[✓]\033[m %s completed successfully\n" "mise run ${task}"
            done
        fi
    fi
}

initialize() {
    header "🚀 Starting initialization process..."
    printf "\033[90m────────────────────────────────────────\033[m\n"

    if [ "$(uname -s)" != "Linux" ]; then
        error "This setup script supports Linux only."
        exit 1
    fi

    # ARM64環境で特別な処理が必要な場合の準備
    if [ "$ARCH_TYPE" = "arm64" ]; then
        printf "\033[93m⚡ ARM64 architecture detected\033[m\n"
        # ARM64用のパッケージソースを追加する等の処理
        export ARCH_TYPE
        export ARCH_DEB
    fi

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

    # Mise managed tools
    if [ -f "$MISE_CONFIG_PATH" ]; then
        printf "\n\033[36m┌─ Mise Managed Tools ────────────────────────────────────────────┐\033[m\n"
        mise_tools=$(awk '
            /^\[tools\]/{f=1; next}
            /^\[/{f=0}
            f && /=/ {
                gsub(/#.*/, "", $0)
                gsub(/[[:space:]]+/, "", $0)
                split($0, a, "=")
                gsub(/^"|"$/, "", a[1])
                if (a[1] != "") print a[1]
            }
        ' "$MISE_CONFIG_PATH")

        echo "$mise_tools" | while IFS= read -r tool; do
            if [ -n "$tool" ]; then
                check_installed_status "$tool" "\033[36m"
            fi
        done
        printf "\033[36m└─────────────────────────────────────────────────────────────────┘\033[m\n"

        printf "\n\033[35m┌─ Mise Optional Tasks ────────────────────────────────────────────┐\033[m\n"
        optional_tasks=$(awk '
            /^\[tasks.optional\]/{f=1; next}
            /^\[/{f=0}
            f && /mise run/ {
                gsub(/.*mise run /, "", $0)
                gsub(/[" ,\]]/, "", $0)
                if ($0 != "") print $0
            }
        ' "$MISE_CONFIG_PATH")
        if [ -n "$optional_tasks" ]; then
            echo "$optional_tasks" | while IFS= read -r task; do
                if [ -n "$task" ]; then
                    check_installed_status "$task" "\033[35m"
                fi
            done
        fi
        printf "\033[35m└─────────────────────────────────────────────────────────────────┘\033[m\n"
    fi

    # Dotfiles
    printf "\n\033[32m┌─ Dotfiles ──────────────────────────────────────────────────────┐\033[m\n"

    # 通常のdotfilesを取得（.claudeと.config/nvimは除外したまま）
    all_dotfiles=$(get_dotfiles)

    # 通常のdotfilesを表示（差分チェック付き）
    echo "$all_dotfiles" | while IFS= read -r f; do
        if [ -n "$f" ]; then
            if [ -L "$HOME/$f" ]; then
                # シンボリックリンクの場合、リンク先が正しいかチェック
                if [ "$(readlink "$HOME/$f")" = "$DOTFILES_PATH/$f" ]; then
                    printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" "$f (symlink)"
                else
                    printf "\033[32m│\033[m \033[33m~\033[m %-61s \033[32m│\033[m\n" "$f (wrong symlink)"
                fi
            elif [ -f "$HOME/$f" ]; then
                # 通常ファイルの場合、内容を比較
                if diff -q "$DOTFILES_PATH/$f" "$HOME/$f" >/dev/null 2>&1; then
                    printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" "$f (file synced)"
                else
                    printf "\033[32m│\033[m \033[33m~\033[m %-61s \033[32m│\033[m\n" "$f (file outdated)"
                fi
            else
                printf "\033[32m│\033[m \033[90m○\033[m %-61s \033[32m│\033[m\n" "$f"
            fi
        fi
    done

    # .config/nvimディレクトリの特別処理
    if [ -d "$DOTFILES_PATH/.config/nvim" ]; then
        if [ -L "$HOME/.config/nvim" ]; then
            printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" ".config/nvim (symlink)"
        else
            printf "\033[32m│\033[m \033[90m○\033[m %-61s \033[32m│\033[m\n" ".config/nvim (symlink)"
        fi
    fi

    # .config/zellijディレクトリの特別処理
    if [ -d "$DOTFILES_PATH/.config/zellij" ]; then
        if [ -L "$HOME/.config/zellij" ]; then
            printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" ".config/zellij (symlink)"
        else
            printf "\033[32m│\033[m \033[90m○\033[m %-61s \033[32m│\033[m\n" ".config/zellij (symlink)"
        fi
    fi

    # .claudeディレクトリの特別処理（サブディレクトリ単位で表示）
    if [ -d "$DOTFILES_PATH/.claude" ]; then
        # .claudeディレクトリ直下のファイル
        direct_files=$(find "$DOTFILES_PATH/.claude" -maxdepth 1 -type f | wc -l)
        if [ "$direct_files" -gt 0 ]; then
            if [ -d "$HOME/.claude" ]; then
                # 直下のファイルをチェック
                diff_count=0
                for source_file in $(find "$DOTFILES_PATH/.claude" -maxdepth 1 -type f); do
                    target_file="$HOME/.claude/$(basename "$source_file")"
                    if [ ! -f "$target_file" ] || ! diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
                        diff_count=$((diff_count + 1))
                        break
                    fi
                done

                if [ "$diff_count" -eq 0 ]; then
                    printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" ".claude/* (files synced)"
                else
                    printf "\033[32m│\033[m \033[33m~\033[m %-61s \033[32m│\033[m\n" ".claude/* (files outdated)"
                fi
            else
                printf "\033[32m│\033[m \033[90m○\033[m %-61s \033[32m│\033[m\n" ".claude/* (files)"
            fi
        fi

        # 各サブディレクトリをチェック
        for subdir in $(find "$DOTFILES_PATH/.claude" -maxdepth 1 -type d ! -path "$DOTFILES_PATH/.claude" | sort); do
            subdir_name=$(basename "$subdir")

            if [ -d "$HOME/.claude/$subdir_name" ]; then
                # サブディレクトリのファイル数をチェック
                source_files=$(find "$subdir" -type f | wc -l)
                target_files=$(find "$HOME/.claude/$subdir_name" -type f 2>/dev/null | wc -l)

                if [ "$source_files" -eq "$target_files" ]; then
                    # 内容の同一性をチェック
                    diff_count=0
                    for source_file in $(find "$subdir" -type f); do
                        relative_path=${source_file#$subdir/}
                        target_file="$HOME/.claude/$subdir_name/$relative_path"

                        if [ ! -f "$target_file" ] || ! diff -q "$source_file" "$target_file" >/dev/null 2>&1; then
                            diff_count=$((diff_count + 1))
                            break
                        fi
                    done

                    if [ "$diff_count" -eq 0 ]; then
                        printf "\033[32m│\033[m \033[32m✓\033[m %-61s \033[32m│\033[m\n" ".claude/$subdir_name/ (synced)"
                    else
                        printf "\033[32m│\033[m \033[33m~\033[m %-61s \033[32m│\033[m\n" ".claude/$subdir_name/ (outdated)"
                    fi
                else
                    printf "\033[32m│\033[m \033[33m~\033[m %-61s \033[32m│\033[m\n" ".claude/$subdir_name/ (partial)"
                fi
            else
                printf "\033[32m│\033[m \033[90m○\033[m %-61s \033[32m│\033[m\n" ".claude/$subdir_name/"
            fi
        done
    fi
    printf "\033[32m└─────────────────────────────────────────────────────────────────┘\033[m\n"

    printf "\n\033[90mLegend: \033[32m✓\033[90m Installed  \033[33m~\033[90m Outdated/Partial  \033[90m○\033[90m Not installed\033[m\n"
}

# インストール状態をチェックして表示する関数
check_installed_status() {
    local script_name=$1
    local frame_color=${2:-"\033[90m"} # デフォルトは灰色
    local installed=false
    local status_icon="\033[90m○\033[m"
    local version_info=""

    # 例外的なケースのみ個別に定義
    case $script_name in
    golang)
        if [ -n "$(command -v go)" ]; then
            installed=true
            version_info="$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')"
        fi
        ;;
    rust)
        if [ -n "$(command -v cargo)" ]; then
            installed=true
            version_info="$(cargo --version 2>/dev/null | awk '{print $2}')"
        fi
        ;;
    neovim)
        if [ -n "$(command -v nvim)" ]; then
            installed=true
            version_info="$(nvim --version 2>/dev/null | head -n1 | awk '{print $2}')"
        fi
        ;;
    graphviz)
        if [ -n "$(command -v dot)" ]; then
            installed=true
            version_info="$(dot -V 2>&1 | head -n1 | awk '{print $5}')"
        fi
        ;;
    typescript)
        if [ -n "$(command -v tsc)" ]; then
            installed=true
            version_info="$(tsc --version 2>/dev/null | awk '{print $2}')"
        fi
        ;;
    python)
        if [ -n "$(command -v python3)" ]; then
            installed=true
            version_info="$(python3 --version 2>/dev/null | awk '{print $2}')"
        fi
        ;;
    postgresql)
        if [ -n "$(command -v psql)" ]; then
            installed=true
            version_info="$(psql --version 2>/dev/null | awk '{print $3}')"
        fi
        ;;
    tmux)
        if [ -n "$(command -v tmux)" ]; then
            installed=true
            version_info="$(tmux -V 2>/dev/null | awk '{print $2}')"
        fi
        ;;
    tpm)
        if [ -d "$HOME/.tmux/plugins/tpm" ]; then
            installed=true
            if command -v git >/dev/null 2>&1; then
                version_info="$(git -C "$HOME/.tmux/plugins/tpm" rev-parse --short HEAD 2>/dev/null || true)"
            fi
        fi
        ;;
    sdkman)
        if [ -d "$HOME/.sdkman" ]; then
            installed=true
            if [ -f "$HOME/.sdkman/var/version" ]; then
                version_info="$(cat "$HOME/.sdkman/var/version" 2>/dev/null)"
            fi
        fi
        ;;
    font)
        # fonts-noto-cjk と fonts-noto-cjk-extra がインストールされているかチェック
        if dpkg -l | grep -q "fonts-noto-cjk " && dpkg -l | grep -q "fonts-noto-cjk-extra "; then
            installed=true
            version_info="$(dpkg -l | grep 'fonts-noto-cjk ' | awk '{print $3}' | head -n1)"
        fi
        ;;
    dependencies)
        # dependenciesは常に表示しない
        return
        ;;
    *)
        # デフォルト: スクリプト名と同じコマンドをチェック
        if [ -n "$(command -v $script_name)" ]; then
            installed=true
            # 汎用的なバージョンチェック
            if $script_name --version >/dev/null 2>&1; then
                version_info="$($script_name --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)"
            elif $script_name -v >/dev/null 2>&1; then
                version_info="$($script_name -v 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)"
            elif $script_name version >/dev/null 2>&1; then
                version_info="$($script_name version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)"
            fi
        fi
        ;;
    esac

    if [ "$installed" = true ]; then
        status_icon="\033[32m✓\033[m"
    fi

    # バージョン情報がある場合は表示名に追加
    display_name="$script_name"
    if [ -n "$version_info" ]; then
        # バージョン番号が既に'v'で始まっている場合は追加しない
        if [[ "$version_info" =~ ^v ]]; then
            display_name="$script_name ($version_info)"
        else
            display_name="$script_name (v$version_info)"
        fi
    fi

    printf "%b│%b %b %-61s %b│%b
" "$frame_color" "\033[m" "$status_icon" "$display_name" "$frame_color" "\033[m"
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

    if [ -d "$DOTFILES_PATH/.config/zellij" -a ! -e "$HOME/.config/zellij" ]; then
        printf "\n\033[36m🧩 Linking Zellij configuration...\033[m\n"
        symlink_cmd $DOTFILES_PATH/.config/zellij $HOME/.config/zellij
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
