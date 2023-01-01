#! /bin/bash

# firefox
# BROWSER="/mnt/c/Program Files/Mozilla Firefox/firefox.exe"

# chrome
# BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# edge
regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
BROWSER="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"

if [ -n "$1" ]; then
    if [[ $1 =~ $regex ]]; then
        TARGET=$1
    else
        TARGET=$(wslpath -w $(readlink -f $1))
    fi
else
    TARGET="$HOME"
fi

"$BROWSER" $TARGET
