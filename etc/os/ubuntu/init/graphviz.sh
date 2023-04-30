#!/bin/bash

dot -V || if [ -z "$(command -v dot)" ]; then
    sudo apt-get update -y
    sudo apt-get install -y graphviz
fi
