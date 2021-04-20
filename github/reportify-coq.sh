#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

do_error=""
do_warning=""

for i in 1 2; do
    if [ "$1" == "--warnings" ]; then
        do_warning=yes
        shift
    elif [ "$1" == "--errors" ]; then
        do_error=yes
        shift
    fi
done

pat=""

case $do_warning,$do_error in
    yes,yes)
        pat='Warning\|Error'
        ;;
    yes,)
        pat='Warning'
        ;;
    ,yes)
        pat='Error'
        ;;
    *)
        ;;
esac

if [ -z "$pat" ]; then
    "$@"
else
    "$@" 2> >("$DIR/reportify-coq-errors-gen.sh" "$pat" >&2)
fi
