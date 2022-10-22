#!/usr/bin/env bash

######################################################################
# Record the compilation performance of every commit of a given branch
# against its parent, updating only the files that have changed.
#
# USAGE: etc/coq-scripts/timing/make-pretty-timed-only-diff-branch.sh BASE_SHA BRANCH -j<NUMBER OF THREADS TO USE>
#
# Set FORCE_REBUILD=1 to rebuild even commits that have already been
# timed.
######################################################################

# in case we're run from out of git repo
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/../pushd-root.sh"

# exit immediately if killed
trap "exit 1" SIGHUP SIGINT SIGTERM

base="$1"
shift
branch="$1"
shift

if [ -z "$base" ] || [ -z "$branch" ]; then
    >&2 echo "USAGE: $0 BASE_SHA BRANCH [MAKE_ARG ..]"
    exit 1
fi

# ensure that we have no changes
if [ ! -z "$(git status 2>&1 | grep '^# Changes to be committed:$')" ]
then
    git status
    echo 'ERROR: You have staged but uncomitted changes.'
    echo '       Either `git stash` them, or `git commit` them, or remove them.'
    exit 1
fi

git checkout "$branch" || exit 1
git submodule update --init --recursive || exit 1

n="$(git log ${base}..${branch} --oneline | wc -l)"
newspecs="$(for i in $(seq $n -1 0); do echo "${branch}$(for j in $(seq 1 $i); do echo -n ^; done)"; done)"
oldfile=""
buildfailures=()

# get the names of the files we use
source "$DIR"/make-pretty-timed-defaults.sh "$@"

$MAKECMD -k --output-sync

# make the old version

# if we're interrupted, first run `git checkout $HEAD` to clean up
trap "git checkout '${branch}'; git submodule update --recursive; exit 1" SIGHUP SIGINT SIGTERM

# we want the same set of files to be built on every commit, so we
# pre-emptively run through all the commits to checkout all the files
# before each build
function dirty_files() {
    local spec
    for spec in $newspecs; do
        git checkout "$spec" || exit 1
        git submodule update --init --recursive || exit 1
    done
}


for spec in $newspecs; do
    dirty_files
    git checkout "$spec" || exit 1
    git submodule update --init --recursive || exit 1
    cursha="$(git log -1 --format=%h)"
    curfile="time-of-build-${cursha}.log"
    if [ ! -f "$curfile" ] || [ ! -z "${FORCE_REBUILD}" ]; then
        #make clean -k; find . -name "*.vo" -delete
        { rm -f "${curfile}.ok"; $MAKECMD -k TIMED=1 --output-sync 2>&1 && touch "${curfile}.ok"; } | tee "${curfile}.tmp"
        rm "${curfile}.ok" && mv "${curfile}.tmp" "$curfile" || true
    fi
    if [ ! -z "${oldfile}" ]; then
        if [ ! -f "${oldfile}" ]; then
            echo "Missing ${oldfile}!"
        else
            if [ ! -f "${curfile}" ]; then
                buildfailures+=("$(git log -1 --format="%C(auto) %h %s")")
                echo "Missing ${curfile} (probable build failure)"
            else
                "${DIR}"/make-both-time-files.py "${curfile}" "${oldfile}" "${BOTH_TIME_FILE}"
                { if ! git log -1 | grep -q 'Timing Diff'; then
                      git log -1 --pretty=%B
                      echo
                  else
                      git log -1 --pretty=%B | sed -n '/Timing Diff/q;p'
                  fi
                  echo '<details><summary>Timing Diff</summary>'
                  echo '<p>'
                  echo
                  echo '```'
                  cat "${BOTH_TIME_FILE}"
                  echo
                  echo '```'
                  echo '</p>'
                  echo '</details>'
                } | git commit --amend -F -
                # copy over the timing log to the new sha
                prevcurfile="$curfile"
                cursha="$(git log -1 --format=%h)"
                curfile="time-of-build-${cursha}.log"
                cp "$prevcurfile" "$curfile"
                git checkout "$branch" && git rebase "$cursha" || exit 1
            fi
        fi
    fi
    oldfile="$curfile"
done

for failure in "${buildfailures[@]}"; do
    echo "Build failed: $failure"
done
