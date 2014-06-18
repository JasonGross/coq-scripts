#!/usr/bin/env bash

# This is a helper script for make-pretty-timed.sh and
# make-pretty-timed-diff.sh.

# in case we're run from out of git repo
PUSHD_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$PUSHD_ROOT_DIR" 1>/dev/null

# now change to the git root; use `cd` so we only need one `popd`
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

# We assume that we're a git submodule, so we need to do this once more
cd ..
# now change to the git root; use `cd` so we only need one `popd`
ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

# Now find a makefile.  We assume that the top-level makefile is last
# in git ls-files; we want to pick up everything, whether it is cached
# or just laying around
MAKEFILE="$(git ls-files --cached --others *Makefile *makefile *GNUmakefile | tail -1)"
if [ ! -z "$MAKEFILE" ]; then
    cd "$(dirname "$MAKEFILE")"
else
    echo "WARNING: No Makefile,makefile,GNUmakefile found in git ls-files"
fi
