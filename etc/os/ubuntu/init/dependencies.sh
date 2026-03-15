#!/bin/bash

SUDO="sudo"

if [ -z "$(command -v sudo)" ]; then
    if [ "$UID" -eq 0 ]; then
        SUDO=""
    else
        echo "sudo is required to install dependencies." >&2
        exit 1
    fi
fi

$SUDO apt-get update -y
$SUDO apt-get install -y git curl libc6 wget gpg clang libclang-dev llvm-dev
