#!/usr/bin/env bash

set -e

if [[ -z "${skip_unterminated_message_warning+x}" ]]; then
    # default value
    skip_unterminated_message_warning="" # empty means "don't skip"
fi

if [[ -z "${forbid_unterminated_errors+x}" ]]; then
    # default value
    forbid_unterminated_errors="" # empty means "don't forbid"
fi

for i in 1; do
    if [ "$1" == "--forbid-unterminated-errors" ]; then
        forbid_unterminated_errors=yes
        shift
    fi
done

if [[ -z "${SED+x}" ]]; then
    # default value
    SED="sed"
fi

if [[ -z "${SED_E+x}" ]]; then
    # default value
    SED_E="${SED} -E"
fi

if [[ -z "${GREP+x}" ]]; then
    # default value
    GREP="grep"
fi

if [[ -z "${GREP_Q+x}" ]]; then
    # default value
    GREP_Q="${GREP} -q"
fi

# e.g., "Warning\|Error"
warnerr="$1"
curlines=()
first_line_regex='\(-\s\+\)\?File "\([^ "]\+\)", line \([0-9]\+\), characters \([0-9]\+-[0-9]\+\):\s*'
second_line_regex='\(-\s\+\)\?\('"$warnerr"'\):\s*'
last_line_regex='\[\([^],]\+\),\([^]]\+\)\]\s*$\|^\(-\s\+\)\?Command exited with non-zero status 1$'
file_line_char_warn_regex="^${first_line_regex}"'\(%0A\s*\)\?'"${second_line_regex}"
invalid_error_regex=(
    "^${first_line_regex}"
    '^\(-\s\+\)\?\(COQC\|OCAMLC\|OCAMLOPT\|COQDEP\) ' # new build file, presumably we missed the end of the error
    '^\(-\s\+\)\?[^\s]\+ (real: [0-9\.]*, user: [0-9\.]*, sys: [0-9\.]*, mem: [0-9]* ko)' # output of make TIMED=1, we probably missed the end of the warning/error
    '^\(-\s\+\)\?make\(\[[0-9]\+\]\):' # we ended up back in make output
    '^\(-\s\+\)\?::' # already a message to GH
)

function format_message() {
    if printf '%s\n' "$1" | ${GREP_Q} "${file_line_char_warn_regex}"; then
        printf '%s\n' "$1" | ${SED} "s~${file_line_char_warn_regex}~"'::error severity=\7,file=\2,line=\3,col=\4::~g; s~^\(::[^:]*\)::\(.*\)\[\([^,]\+\),\([^]]\+\)\]\s*$~\1,code=\3%2C\4::\2~g; s/^::error severity=[Ee][Rr][Rr][Oo][Rr],/::error /g; s/^::error severity=[Ww][Aa][Rr][Nn][Ii][Nn][Gg],/::warning /g' | ${SED_E} ':a; s/(code=[^,:]*),/\1%2C/; ta'
    else
        printf '%s\n' "$1" | ${SED} 's/%0A/\n/g'
    fi
}

function join_to_oneline() {
    sep=""
    for i in "$@"; do
        printf '%s' "${sep}${i}"
        sep="%0A"
    done
}

function format_curlines_first_two() {
    if [ -z "${skip_unterminated_message_warning}" ]; then # first we report on the fact that we have an unterminated warning:
        printf '%s' "::warning::Could not find a terminator for ${#curlines[@]}-line warning:%0A"
        join_to_oneline "${curlines[@]}"
        printf '\n'
    fi
    format_message "$(join_to_oneline "${curlines[@]:0:2}")" # slice of length 2 starting at 0
    for i in "${curlines[@]:2}"; do # slice to the end starting from 2
        printf '%s\n' "$i"
    done
}

function invalid_line() {
    for i in "${invalid_error_regex[@]}"; do
        if printf '%s\n' "$1" | ${GREP_Q} "$i"; then
            return 0 # we found an invalid line, so we succeed
        fi
    done
    return 1
}

while read line
do
    if [ "${#curlines[@]}" -gt 0 ]; then # we're in the middle of an error
        if printf '%s\n' "$line" | ${GREP_Q} "${last_line_regex}"; then # we found the end
            curlines+=("$line")
            format_message "$(join_to_oneline "${curlines[@]}")"
            curlines=()
            continue
        elif invalid_line "$line"; then # this line is not a valid part of an error, so we print only the first two lines and then dump the rest
            format_curlines_first_two
            curlines=()
        fi
    fi
    if [ "${#curlines[@]}" -gt 0 ]; then # we're still in the middle of an error, so just accumulate
        curlines+=("$line")
    elif printf '%s\n' "$line" | ${GREP_Q} "^${first_line_regex}"; then # we weren't in an error, and we've now found the first line of an error
        curlines+=("$line")
    else # no error here, just pipe through
        printf '%s\n' "$line"
    fi
done

if [ "${#curlines[@]}" -gt 0 ]; then # we have an unterminated warning or error
    if [ -z "${forbid_unterminated_errors}" ] && printf '%s\n' "${curlines[1]}" | ${GREP_Q} "Error"; then # unterminated errors are allowed, and this is an error
        format_message "$(join_to_oneline "${curlines[@]}")"
        curlines=()
    else # just print the first two lines
        format_curlines_first_two
        curlines=()
    fi
fi
