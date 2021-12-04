
$VSCODE_PATH = "$env:USERPROFILE\.dotfiles\etc\os\windows\vscode"

code.cmd --list-extensions | Out-File -Encoding utf8 $VSCODE_PATH\extensions
