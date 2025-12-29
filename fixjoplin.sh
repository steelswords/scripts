#!/usr/bin/env bash
# File:        fixjoplin.sh
# Author:      Tristan Andrus
# Description: Fixes Joplin, which won't start if it was closed in fullscreen mode
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

# Function to set "isMaximized" and "isFullscreen" to false in the root JSON object of a given file
fix_joplin_config() {
    local file_path="$1"

    # Check if the file exists
    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found!"
        return 1
    fi

    echo "Killing all joplin instances"
    killall --ignore-case --regexp '^.*tmp.*joplin$' ||:
    killall --ignore-case joplin ||:

    echo "Fixing config file"
    # Use jq to update the JSON object
    jq '.isMaximized = false | .isFullscreen = false' "$file_path" > temp.json && mv temp.json "$file_path"
    chmod -w "$file_path"

    echo "New config file:"
    cat "$file_path"
}

fix_joplin_config "$HOME/.config/joplin-desktop/window-state-prod.json"
