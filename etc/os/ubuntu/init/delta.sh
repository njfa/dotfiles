#!/bin/sh

if [ -z "${DELTA_VERSION:-}" ]; then
    echo "DELTA_VERSION is not set."
    exit 1
fi

is_installed=false

if command -v delta >/dev/null 2>&1; then
    version="$(delta --version | awk '{print $2}')"
    echo "delta is installed. required version: $DELTA_VERSION. now version: $version"

    [ "$version" = "$DELTA_VERSION" ] && is_installed=true
else
    echo "delta is not installed. required version: $DELTA_VERSION."
fi

# deltaのインストール
if ! $is_installed; then
    arch=$(dpkg --print-architecture)
    curl -Lo git-delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${arch}.deb"

    sudo dpkg -i git-delta.deb
    rm git-delta.deb
fi
