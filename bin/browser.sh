#! /bin/sh

# firefox
# BROWSER="/mnt/c/Program Files/Mozilla Firefox/firefox.exe"

# chrome
# BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# edge
BROWSER="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"

if [ -n "$1" ]; then
    TARGET=$(readlink -f $1)
else
    TARGET="$HOME"
fi

# if need file URI pattern
if echo $0 | grep -q "browser.sh"; then
  "$BROWSER" "file:////wsl$/$WSL_DISTRO_NAME$TARGET"
  exit 0
fi

"$BROWSER" $TARGET
