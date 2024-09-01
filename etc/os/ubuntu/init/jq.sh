#!/bin/bash

if command -v jq >/dev/null 2>&1; then
    echo "jq is installed."
else
    echo "jq is not installed."

    sudo apt-get install -y jq
fi


