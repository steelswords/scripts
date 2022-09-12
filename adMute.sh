#!/bin/bash
# Name:        adMute.sh
# Author:      Tristan Andrus
# Description: Uses pactl to mute audio for 15-30 seconds so you don't have to hear an ad.
################################################################################

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

function toggleMute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle
}

toggleMute
sleep 30
toggleMute

# TODO: Make it so you can "hit" this script so that you can call it multiple times
# to extend the time as long as you have more than, Idk, 3 seconds of mute time left.
