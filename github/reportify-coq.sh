#!/usr/bin/env bash

set -e -o pipefail

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
    # we might just do 2> >(script >&2), but the script might die, cf https://stackoverflow.com/questions/3618078/pipe-only-stderr-through-a-filter/52575213#comment105555334_52575087
    { "$@" 3>&1 1>&2 2>&3 3>&- | "$DIR/reportify-coq-errors-gen.sh" "$pat"; } 3>&1 1>&2 2>&3 3>&-
fi
