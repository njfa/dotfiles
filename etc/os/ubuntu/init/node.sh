#!/bin/bash

if [ -z "$(command -v node)" ]; then
    sudo apt install -y nodejs npm
    sudo npm install n -g
    sudo n stable
    sudo apt purge -y nodejs npm
fi
