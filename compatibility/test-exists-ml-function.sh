#!/bin/bash

set -x

FILE="conftest.ml"

function cleanup () {
    PREFILE="${FILE%.ml}"
    rm -f "$PREFILE.cmi" "$PREFILE.cmo" "$PREFILE.cmx" "$PREFILE.cmxs" "$PREFILE.ml.d" "$PREFILE.o" "$FILE" "$MAKEFILE"
}

trap cleanup EXIT

cat > "$FILE" <<EOF
let test = $FUNCTION
EOF

cat "$FILE"

"${COQBIN}coq_makefile" "$FILE" -R . Top | make -f - || exit 1

exit 0
