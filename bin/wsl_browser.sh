#! /bin/sh

# firefox
# BROWSER="/mnt/c/Program Files/Mozilla Firefox/firefox.exe"

# chrome
# BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# edge
BROWSER="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"

# if need file URI pattern
if echo $0 | grep -q "wsl_browser.sh"; then
  "$BROWSER" "file:////wsl$/$WSL_DISTRO_NAME${1}"
  exit 0
fi

"$BROWSER" $1
