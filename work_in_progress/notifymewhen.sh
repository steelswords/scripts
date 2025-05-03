#!/usr/bin/env bash
# File:        notifymewhen.sh
# Author:      Tristan Andrus
# Description: Notifies when something happens, dependent on command line arguments
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

function print_usage() {
    echo "Usage: $0 notifymewhen.sh [-p processid]"
    exit 1
}

if [[ $# -ne 2 ]]; then
    print_usage
fi

notify_condition="${1:-}"
notify_argument="${2:-}"

if [[ '-p' == "$notify_function" ]]; then
    notify_function="psauxgrep"
else
    print_usage
fi


