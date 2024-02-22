#!/bin/bash

symbol_clean="#[fg=green,bg=#363a43] ✔"
symbol_ahead="#[fg=green,bg=#363a43]⇡ "
symbol_behind="#[fg=green,bg=#363a43]⇣ "
symbol_merging="#[fg=magenta,bg=#363a43]⚡︎"
symbol_modified="#[fg=yellow,bg=#363a43]*"
symbol_staged="#[fg=yellow,bg=#363a43]+"
symbol_untracked="#[fg=yellow,bg=#363a43]~"

git_info() {
    cd $1
    local current_path="$1"
    local git_info
    local ref=`command git symbolic-ref --short HEAD 2>/dev/null`
    if [ -z "$ref" ]; then
        ref=`command git show-ref --head -s --abbrev 2>/dev/null | head -n1 2>/dev/null`
    fi

    if [ ! -z "$ref" ]; then
        local git_toplevel=`command git rev-parse --show-toplevel 2>/dev/null`
        local git_status=`command git status --branch --porcelain 2>/dev/null`
        local git_info="#[bg=#363a43,fg=colour255] $ref"
        local ref_list=`command git rev-list --left-right '@{upstream}...HEAD' 2>/dev/null`
        local num_ahead=`echo -e "$ref_list" | grep "^>" | wc -l`
        local num_behind=`echo -e "$ref_list" | grep "^<" | wc -l`
        local is_modified=`echo -e "$git_status" | grep -E '^[ MARC]M'`
        local is_staged=`echo -e "$git_status" | grep -E '^[MARC]'`
        local is_untracked=`echo -e "$git_status" | grep -E '^\?'`
        local git_relative_path=`realpath --relative-to="$git_toplevel" "$current_path"`

        local flags
        if [ ! -z "$is_modified" ]; then
            flags="$flags$symbol_modified"
        fi

        if [ ! -z "$is_staged" ]; then
            flags="$flags$symbol_staged"
        fi

        if [ ! -z "$is_untracked" ]; then
            flags="$flags$symbol_untracked"
        fi

        if [ $num_ahead -gt 0 ]; then
            flags="$flags $symbol_ahead$num_ahead"
        fi

        if [ $num_behind -gt 0 ]; then
            flags="$flags $symbol_behind$num_behind"
        fi

        if [ -z "$flags" ]; then
            flags=$symbol_clean
        fi

        git_info="#[fg=#262a33,bg=#363a43] $git_info$flags #[bg=#262a33,fg=#363a43]"
        if [ ! -z "$git_relative_path" ]; then
            current_path=$git_toplevel
            git_info="$git_info#[fg=#262a33,bg=#363a43]#[fg=colour255,bg=#363a43] $git_relative_path #[bg=#262a33,fg=#363a43]"
        fi
    fi

    echo "#[fg=#7aa2f7,bg=#262a33]#[fg=colour255,bg=#7aa2f7] #{pane_pid} #[fg=#7aa2f7,bg=#262a33]#[fg=#262a33,bg=#363a43]#[fg=colour255,bg=#363a43] #(whoami) #[bg=#262a33,fg=#363a43]#[fg=#262a33,bg=#363a43]#[fg=colour255,bg=#363a43] $current_path #[bg=#262a33,fg=#363a43]$git_info#[fg=#262a33,bg=#7aa2f7]#[bg=#262a33,fg=#7aa2f7]#[default]"
}

if [[ $2 = "ssh" ]]; then
    pane_pid=$3
    info=$({ pgrep -flaP $pane_pid ; ps -o command -p $pane_pid; } | xargs -I{} echo {} | awk '/ssh/' | sed -E 's/^[0-9]*[[:blank:]]*ssh //')
    port=$(echo $info | grep -Eo '\-p ([0-9]+)'|sed 's/-p //')
    if [ -z $port ]; then
        local port=22
    fi
    info=$(echo $info | sed 's/\-p '"$port"'//g')
    user=$(echo $info | awk '{print $NF}' | cut -f1 -d@)
    host=$(echo $info | awk '{print $NF}' | cut -f2 -d@)

    if [ $user = $host ]; then
        user=$(whoami)
        list=$(awk '
        $1 == "Host" {
            gsub("\\\\.", "\\\\.", $2);
            gsub("\\\\*", ".*", $2);
            host = $2;
            next;
        }
        $1 == "User" {
        $1 = "";
            sub( /^[[:space:]]*/, "" );
            printf "%s|%s\n", host, $0;
        }' ~/.ssh/config
        )
        echo $list | while read line; do
        host_user=${line#*|}
        if [[ "$host" =~ $line ]]; then
            user=$host_user
            break
        fi
        done
    fi
    ssh_hostname=" ssh:$user@$host "
    echo "#[fg=#7aa2f7,bg=#262a33]#[fg=colour255,bg=#7aa2f7] #{pane_pid} #[fg=#7aa2f7,bg=#262a33]#[fg=#262a33,bg=#363a43]#[fg=colour255,bg=#363a43] $user #[bg=#262a33,fg=#363a43]#[fg=#262a33,bg=#363a43]#[fg=colour255,bg=#363a43] $host #[bg=#262a33,fg=#363a43]#[default]"
else
    git_info $1
fi
