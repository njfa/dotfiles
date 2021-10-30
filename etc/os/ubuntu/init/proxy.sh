#!/bin/bash

if [ -z "$(command -v connect)" ]; then
    sudo apt install -y connect-proxy
fi