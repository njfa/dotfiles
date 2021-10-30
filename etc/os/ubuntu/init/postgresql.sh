#!/bin/bash

if [ -z "$(command -v psql)" ]; then
    sudo apt update -y
    sudo apt install -y postgresql postgresql-contrib
fi