#!/bin/bash

SUDO="sudo"

if [ -z "$(command -v sudo)" ]; then
    if [ "$UID" -eq 0 ]; then
        SUDO=""
    else
        echo "Skipping OS dependencies: sudo is unavailable and current user is not root." >&2
        exit 0
    fi
fi

$SUDO apt-get update -y
$SUDO apt-get install -y git curl libc6 wget gpg clang libclang-dev llvm-dev
