#!/bin/bash

# nvimを使用する際に必要になる
if [ -z "$(command -v node)" ]; then
    sudo apt install -y nodejs npm
    sudo npm install n -g
    sudo n stable
    sudo apt purge -y nodejs npm
fi
