# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload -Uz add-zsh-hook

# emacs風キーバインド
bindkey -e
# deleteキーを有効化
bindkey "^[[3~" delete-char

# ディレクトリ名のみ指定で移動
setopt auto_cd

# ディレクトリ移動時に自動でpushdする
setopt auto_pushd

# すでにpushdしているディレクトリはpushdせずに無視する
setopt pushd_ignore_dups

# 同じ履歴が存在する場合は古いものから順に削除する
setopt hist_ignore_all_dups

# スペースから始まる入力は履歴に保存しない
setopt hist_ignore_space

# 履歴をプロセス間で共有
setopt share_history

zstyle ':completion:*:default' menu select=1
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# umaskを指定
umask 022

# lsコマンドに色をつける
export LSCOLORS=gxfxcxdxbxegedabagacad
# 履歴ファイルの保存先
export HISTFILE=$HOME/.zsh_history
# メモリに保存される履歴の件数
export HISTSIZE=1000
# 履歴ファイルに保存される履歴の件数
export SAVEHIST=10000

export BROWSER=browser.sh

export PATH="$HOME/.dotfiles/bin:$PATH"

# -------------------------------------------------------------------
# python (pyenv+uv)
# -------------------------------------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# -------------------------------------------------------------------
# rust
# -------------------------------------------------------------------
if [ -f "$HOME/.cargo/env" ]; then
    source $HOME/.cargo/env
fi

# -------------------------------------------------------------------
# golang
# -------------------------------------------------------------------
export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"

# -------------------------------------------------------------------
# tfenv
# -------------------------------------------------------------------
export PATH="$HOME/.tfenv/bin:$PATH"

# -------------------------------------------------------------------
# lazydocker
# -------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# -------------------------------------------------------------------
# yq
# -------------------------------------------------------------------
export PATH="$HOME/.yq/bin:$PATH"

# -------------------------------------------------------------------
# opencode
# -------------------------------------------------------------------

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# -------------------------------------------------------------------
# 関数
# -------------------------------------------------------------------

colortest() {
    awk 'BEGIN{
        s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
        for (colnum = 0; colnum<77; colnum++) {
            r = 255-(colnum*255/76);
            g = (colnum*510/76);
            b = (colnum*255/76);
            if (g>255) g = 510-g;
            printf "\033[48;2;%d;%d;%dm", r,g,b;
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
            printf "%s\033[0m", substr(s,colnum+1,1);
        }
        printf "\n";
    }'
}

fbr() {
    # カレントディレクトリがGitリポジトリ上かどうか
    git rev-parse &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Not a git repository."
        sleep 0.5
        zle accept-line
        return
    fi

    local branches branch
    branches=$(git branch -vv) &&
    branch=$(echo "$branches" | fzf +m) &&
    git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fshow - git commit browser
fshow() {
    # カレントディレクトリがGitリポジトリ上かどうか
    git rev-parse &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Not a git repository."
        sleep 0.5
        zle accept-line
        return
    fi

    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
        --bind "ctrl-m:execute:
                    (grep -o '[a-f0-9]\{7\}' | head -1 |
                    xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                    {}
    FZF-EOF"
}

# fcd - cd to selected directory
fcd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

frbr() {
    # カレントディレクトリがGitリポジトリ上かどうか
    git rev-parse &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Not a git repository."
        sleep 0.5
        zle accept-line
        return
    fi

    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" |
            fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# cw - change worktree
cw() {
    # カレントディレクトリがGitリポジトリ上かどうか
    git rev-parse &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Not a git repository."
        sleep 0.5
        zle accept-line
        return
    fi

    local selectedWorkTreeDir=`git worktree list | fzf | awk '{print $1}'`

    if [ "$selectedWorkTreeDir" = "" ]; then
        # Ctrl-C.
        return
    fi

    cd ${selectedWorkTreeDir}
}

fa() {
    local out q n addfiles
    while out=$(
        git status --short |
        awk '{if (substr($0,2,1) !~ / /) print $2}' |
        fzf --multi --exit-0 --expect=ctrl-d); do
        q=$(head -1 <<< "$out")
        n=$[$(wc -l <<< "$out") - 1]
        addfiles=(`echo $(tail "-$n" <<< "$out")`)
        [[ -z "$addfiles" ]] && continue
        if [ "$q" = ctrl-d ]; then
            git diff --color=always $addfiles | less -R
        else
            git add $addfiles
        fi
    done
}

fssh() {
    local sshLoginHost=$(cat ~/.ssh/config | grep -i ^host | awk '{print $2}' | fzf)

    if [ "$sshLoginHost" = "" ]; then
         return 1
    fi

    BUFFER="ssh ${sshLoginHost}"
    zle accept-line
    zle clear-screen
}

fzf-z-search() {
    local res=$(z | cut -c 12- | tac | fzf --no-sort)
    if [ -n "$res" ]; then
        BUFFER+="cd $res"
        zle accept-line
    else
        return 1
    fi
}

tmux-create-new-session() {
    if [ -z "$(command -v fzf)" ]; then
        echo "fzf not found"
        return
    fi

    new_session="Create New Session"
    session_id=$(echo -e "$new_session\n$(tmux list-sessions 2>/dev/null)" | grep -v ^\$ | fzf | cut -d: -f1)

    if [ "$session_id" = "$new_session" ]; then
        tmux new-session
    elif [ -n "$session_id" ]; then
        tmux attach-session -t "$session_id"
    fi
}

update_tmux() {
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}
add-zsh-hook precmd update_tmux

zle -N fzf-z-search
zle -N cw
# zle -N fbr
# zle -N fshow
zle -N fssh
bindkey '^f' fzf-z-search
# bindkey '^g' cw
# bindkey '^b' fbr
# bindkey '^o' fshow
bindkey '^x' fssh

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi


# -------------------------------------------------------------------
# zinit
# -------------------------------------------------------------------

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/z-a-rust \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-bin-gem-node

### End of Zinit's installer chunk

zinit light zsh-users/zsh-autosuggestions
# zinit load zsh-users/zsh-syntax-highlighting #"ssh"と入力する際にフリーズする
# zinit light zdharma-continuum/fast-syntax-highlighting # このプラグインを使用するとpromptのtruecolorが効かなくなる
zinit light rupa/z
zinit load zdharma-continuum/history-search-multi-word
zinit load romkatv/powerlevel10k

# -------------------------------------------------------------------
# fzf
# -------------------------------------------------------------------
# zinit後に読み込まないとctrl-rの動作が変わる
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# -------------------------------------------------------------------
# p10k
# -------------------------------------------------------------------

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

typeset -g POWERLEVEL9K_DIR_BACKGROUND='#1d202f'
# typeset -g POWERLEVEL9K_DIR_BACKGROUND='#062e32'
typeset -g POWERLEVEL9K_DIR_FOREGROUND='#a9b1ce'
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='#e7e8e9'
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND='#e7e8e9'

typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=2
typeset -g POWERLEVEL9K_STATUS_OK_BACKGROUND='#d67f33'
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=2
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_BACKGROUND='#062e32'

typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='#062e32'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='#f7df68'

typeset -g POWERLEVEL9K_TIME_BACKGROUND='#ffffff'

typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND='#00e8c6'
# typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='#be983e'
typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='#e0af68'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='#9772fd'
typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=3
typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND=8


# -------------------------------------------------------------------
# alias
# -------------------------------------------------------------------

# 2, 3階層上のディレクトリへの移動の簡易化
alias ...='cd ../..'
alias ....='cd ../../..'

if [ -n "${EDITOR}" ]; then
    alias vi=${EDITOR}
    alias vim=${EDITOR}
else
    alias vi=nvim
    alias vim=nvim
fi

alias vimdiff='nvim -d'
alias view='nvim -R'
alias code='code.sh'
alias fd='fdfind'

# lsに色を付ける
alias ls='ls --color=auto'

# ssh時にはTERMを変更
# alias ssh='TERM=xterm ssh'

# tmux開始用関数の文字数が多いのでエイリアスを設定
alias ta='tmux-create-new-session'

# wslのキャッシュをクリア
alias rmcache='sudo sh -c "echo 3 >'/proc/sys/vm/drop_caches' && swapoff -a && swapon -a"'

# plantuml-serverを立てる
alias start-plantuml='rmp >/dev/null 2>&1; docker run -d -p 18123:8080 --name plantuml plantuml/plantuml-server:jetty'
alias stop-plantuml='docker kill plantuml && docker rm $(docker ps -a -q)'

# dockerでnoneのイメージを全て削除
if [ ! -z "$(command -v docker)" ]; then
    alias rmi='docker rmi $(docker images -f "dangling=true" -q)'
    alias rmp='docker rm $(docker ps -a -q)'
fi

# rust製ツールを入れている場合はコマンドを置き換える
if [ ! -z "$(command -v lsd)" ]; then
    alias tree='lsd --tree'
fi

# インタラクティブにjqを使用できるプラグイン (jq依存)
if [ ! -z "$(command -v jq)" ]; then
    zinit light reegnz/jq-zsh-plugin
    bindkey '^j' jq-complete 
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# 一番最後に読み込むと良いらしい
zinit load zsh-users/zsh-syntax-highlighting #"ssh"と入力する際にフリーズする

# 環境固有の情報を読む
[ -f ~/.zshrc_local ] && source ~/.zshrc_local

fpath=($HOME/.zsh/completions $fpath)

# deltaコマンドで使用する補完関数が_deltaであることを明示しないと_sccsになってしまう
[ -f $HOME/.zsh/completions/_delta ] && (( ${+_comps} )) && _comps[delta]=_delta

autoload -Uz compinit && compinit
