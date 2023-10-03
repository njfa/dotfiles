#!/bin/bash


if [ -z "$(command -v sudo)" ]; then
    apt-get update -y
    apt-get install -y sudo
fi

sudo apt-get install -y git curl libc6 wget gpg
