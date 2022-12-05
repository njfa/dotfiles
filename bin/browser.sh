#! /bin/sh

# firefox
# BROWSER="/mnt/c/Program Files/Mozilla Firefox/firefox.exe"

# chrome
# BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# edge
BROWSER="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"

if [ -n "$1" ]; then
    TARGET=$(wslpath -w $(readlink -f $1))
else
    TARGET="$HOME"
fi

"$BROWSER" $TARGET
