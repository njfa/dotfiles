[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('utf-8')

Import-Module posh-git

# キーバインドをEmacs風に変更
Set-PSReadlineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar

# インストールしたコマンドのエイリアスを設定
if ($PSVersionTable.PSVersion.Major -gt 5) {
    # fzfを使用する
    Import-Module PSFzf
    Enable-PsFzfAliases
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

    # Set-Alias ls lsd
    Set-Alias cat bat
    Set-Alias vim nvim
    Set-Alias map Get-PSReadLineKeyHandler
} else {
    # Set-Alias ls lsd -O AllScope
    Set-Alias cat bat -O AllScope
    Set-Alias vim nvim -O AllScope
    Set-Alias map Get-PSReadLineKeyHandler -O AllScope
}

oh-my-posh init pwsh --config "$env:USERPROFILE\.dotfiles\etc\os\windows\night-owl.omp.json" | Invoke-Expression
