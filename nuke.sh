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

function print_usage() {
    echo "Usage: nuke.sh <space separated list of folders and files to securely delete"
}

function nuke_target() {
    shopt -s globstar
    target_file="${1:-}"

    if [[ -d $target_file ]]; then

        find "$target_file" -type f -exec shred -vuz {} \;

        echo "Removing directories now."

        for d in "$target_file"/**; do
            echo " Boom, there goes $d"
            rm -rf "$d"
        done
    elif [[ -f "$target_file" ]]; then
        shred -vuz "$target_file"
        echo " Boom, there goes $target_file"
        rm -rf "$target_file"
    else
        echo "ERROR: $target_file is not a directory or regular file. Quitting."
        exit 1
    fi
    echo "󰚤 Done nuking $target_file! ☢"

    echo "When you're done having fun deleting files, you might want to run

    scrub -X $target_file"
}


# Check if print usage is requested
if [[ $# -eq 0 ]] || [[ $1 == '-h' ]] || [[ $1 == '--help' ]] ; then
    print_usage
    exit 0
fi

# Print files to delete
for d in "$@"; do
    echo "This will delete $d"
done

echo ""


# Get confirmation
read -r -p 'Are you sure?? [y/N] ' confirmation
if [[ "$confirmation" = "y" ]] || [[ "$confirmation" = "Y" ]]; then
    echo "Alright, you asked for it."
    echo "NUKE! 󰚤"
    for target in "$@"; do
        nuke_target "$target"
    done
else
    echo "Did not get user confirmation. Quitting without nuking anything."
    exit 2
fi



