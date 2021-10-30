#!/bin/bash

if [ ! -d "$HOME/.sdkman" ]; then
    curl -s https://get.sdkman.io | bash
fi
