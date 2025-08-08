#!/bin/bash

if command -v psql >/dev/null 2>&1; then
    echo "psql is installed."
else
    echo "psql is not installed."
    sudo apt install -y postgresql postgresql-contrib
fi
