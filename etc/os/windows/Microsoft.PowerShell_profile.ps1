# # Windows Terminalで起動した時のみ適用する
# if ($env:WT_PROFILE_ID) {
Import-Module posh-git
Import-Module oh-my-posh
Set-PoshPrompt -Theme aliens
# }

# キーバインドをEmacs風に変更
Set-PSReadlineOption -EditMode Emacs

# インストールしたコマンドのエイリアスを設定
if ($MAJOR_VERSION -gt 5) {
    Set-Alias ls lsd
    Set-Alias cat bat
} else {
    Set-Alias ls lsd -O AllScope
    Set-Alias cat bat -O AllScope
}

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'