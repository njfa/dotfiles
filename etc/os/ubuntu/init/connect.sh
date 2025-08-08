#!/bin/bash

if command -v connect >/dev/null 2>&1; then
    echo "connect is installed."
else
    echo "connect is not installed."
    sudo apt install -y connect-proxy
fi
