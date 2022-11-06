#!/bin/bash

if [ -z "$(command -v zip)" ]; then
    sudo apt install -y zip
fi

if [ -z "$(command -v unzip)" ]; then
    sudo apt install -y unzip
fi

if [ ! -d "$HOME/.sdkman" ]; then
    curl -s https://get.sdkman.io | bash
fi
