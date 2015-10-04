#!/bin/bash

set -x

FILE="conftest.ml"
MAKEFILE="conftest.mk"

cat > "$FILE" <<EOF
let test = $FUNCTION
EOF

cat "$FILE"

"${COQBIN}coq_makefile" "$FILE" -R . Top -o "$MAKEFILE" || exit 1
make -f "$MAKEFILE" || exit 1

PREFILE="${FILE%.ml}"
rm -f "$PREFILE.cmi" "$PREFILE.cmo" "$PREFILE.cmx" "$PREFILE.cmxs" "$PREFILE.ml.d" "$PREFILE.o" "$FILE" "$MAKEFILE"

exit 0
