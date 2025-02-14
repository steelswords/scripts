#!/usr/bin/env bash
# File:        nuke.sh
# Description: Completely destroy data in a directory
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

function nuke_dir() {
    shopt -s globstar
    dir="${1:-}"

    if [[ ! -d $dir ]]; then
        echo "ERROR: $dir is not a directory. Quitting."
        exit 1
    fi

    find "$dir" -type f -exec shred -vuz {} \;

    echo "Removing directories now."

    for d in "$dir"/**; do
        echo " Boom, there goes $d"
        rm -rf "$d"
    done

    echo "󰚤 Done nuking $dir! ☢"

    echo "When you're done having fun deleting files, you might want to run

    scrub -X $dir"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <directory to nuke>"
    exit 0
fi

dir="${1:-}"

for d in "${directories_to_nuke[@]}"; do
    echo "This will delete $d"
done

echo ""

read -p 'Are you sure?? [y/N] ' confirmation
if [[ "$confirmation" = "y" ]] || [[ "$confirmation" = "Y" ]]; then
    echo "Alright, you asked for it."
    echo "NUKE! 󰚤"
    nuke_dir "$dir"
else
    echo "Did not get user confirmation. Quitting without nuking anything."
    exit 1
fi



