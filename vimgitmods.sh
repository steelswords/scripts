#!/bin/bash
# Name:        vimgitmods.sh
# Author:      Tristan Andrus
# Description: Takes all the files modified in git (since the last commit or a
#              specified one) and opens them all in vim
################################################################################

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

# TODO: Exit with error if not in git repo

targetCommit="${1-HEAD}"

listOfFiles="$(git diff --name-only "$targetCommit" )"
argumentList="$(echo "$listOfFiles" | tr '\n' ' ' )"
cd "$(git rev-parse --show-toplevel)"
vim -p $argumentList
