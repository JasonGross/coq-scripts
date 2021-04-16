#!/usr/bin/env bash

set -e

while read i
do
    # ^File \"([^ \"]+)\", line (\\d+), characters (\\d+-\\d+):
    if [[ "$i" == "File "*:* ]]; then # first line of error
        echo
    fi
    echo -n "$i%0A"
done
echo
