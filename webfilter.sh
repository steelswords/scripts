#!/usr/bin/env sh
# File:        webfilter.sh
# Author:      Tristan Andrus
# Description: Enables or disables filters to different websites
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
#set -o pipefail  # Don't hide errors within pipes

# Uncomment to debug
# set -x

################################################################################


################################################################################
# Script State Variables
################################################################################
WEBSITE=""
USER_DEVICE=""
TIMEOUT=""

################################################################################
# Command line arg parsing
################################################################################
print_usage() {
    echo "Usage: $0 <website> [user_device] [--time timeout]"
    exit 1
}

if [ $# -lt 1 ]; then
    printf "Invalid number of arguments."
    print_usage "$0"
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage "$0"
fi

# Parse command line arguments
while :; do
    case $1 in
        -h|--help)
            print_usage "$0"
            ;;
        -t|--timeout)       # Takes an option argument; ensure it has been specified.
            shift
            if [ "$1" ]; then
                TIMEOUT_RAW="$1"
                TIMEOUT="$(parse_timeout "$1")"
                shift
            else
                print_usage
            fi
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *)               # Default case: No more options, so break out of the loop.
            if [ -n "$1" ]; then # If arg1 is a nonzero length string
                if [ -z "$WEBSITE" ]; then # Set WEBSITE if it isn't set yet
                    WEBSITE="$1"
                    shift
                elif [ -z "$USER_DEVICE" ]; then
                    USER_DEVICE=$1
                    shift
                else
                    echo "Unexpected argument: $1"
                    print_usage "$0"
                fi
            fi
            ;;
    esac

    shift

done

