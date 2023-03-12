#!/bin/sh
# $(wslpath -u "$USERPROFILE\scoop\apps\vscode\current\bin")/code "$@"
CODEPATH=$(which.exe code | cut -c 3-)
"$(wslpath -u "$CODEPATH")" "$@"
