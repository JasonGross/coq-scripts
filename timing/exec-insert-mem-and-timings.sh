#!/bin/bash

pidf="$(mktemp)"
function cleanup() {
    rm -f "${pidf}"
}
trap cleanup EXIT
rm "${pidf}"; mkfifo "${pidf}"
{ "$@" &
  pidv=$!
  echo $pidv >"$pidf"
  wait $pidv; } | {
    read pid <"$pidf"

    PREV_TIME="$(date +%s.%N)"
    PREV_MEM=0

    while read i
    do
        NEXT_TIME="$(date +%s.%N)"
        NEXT_MEM="$(ps -q "$pid" -o rss 2>/dev/null | tail -1 || echo 0)"
        DIFF_TIME="$(echo "${NEXT_TIME} - ${PREV_TIME}" | bc)"
        DIFF_MEM="$(echo "${NEXT_MEM} - ${PREV_MEM}" | bc)"
        if [ "${DIFF_MEM}" -ge 0 ]; then DIFF_MEM="+${DIFF_MEM}"; fi
        printf "%ss %skb: %s\n" "${DIFF_TIME}" "${DIFF_MEM}" "$i"
        PREV_TIME="${NEXT_TIME}"
        PREV_MEM="${NEXT_MEM}"
    done
}
