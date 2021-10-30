#!/bin/bash

if [ -z "$(command -v npm)" ]; then
    PWD=$(cd $(dirname $0); pwd)
    sh $PWD/node.sh
fi

if [ -z "$(command -v tsc)" ]; then
    sudo npm install -g typescript
fi