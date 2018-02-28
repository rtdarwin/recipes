#!/bin/sh

chmod_recursively () {
    if [ -d "$1" ]; then
        chmod 655 "$1"
        # for i in $(ls "$1"); do
        ls "$1" | while read i; do
            chmod_recursively "${1}/${i}"
        done
    else
        chmod 644 "$1"
    fi
}

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
   echo "Usage:"
   echo "  $0 dir|file"
   exit 1
fi

chmod_recursively $1
