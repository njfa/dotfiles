#!/bin/bash

# 第一引数: 実行中のコマンド
# 第二引数: プロセスID

cmd=$1
process_id=$2

# 実行中のコマンドがsshかどうかを判定
if [[ "${cmd,,}" == "ssh" ]]; then
    # sshの場合はssh先の情報を表示
    ssh_info=$(pgrep -aP "$process_id" | grep -oP 'ssh\s+\K[^@]+')
    target=$(echo "$ssh_info" | cut -d' ' -f1)
    echo "${target}"
else
    # sshでない場合は実行しているユーザを表示
    username=$(ps -o user= -p "$2")
    echo "$username"
fi
