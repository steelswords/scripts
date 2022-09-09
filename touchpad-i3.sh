#!/bin/bash
# Name:        touchpad-i3.sh
# Author:      Tristan Andrus
# Description: Enables the touchpad for window managers that don't do it
#              automagically (ahem, i3).
################################################################################

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

# To find this for your computer, run `xinput` and look for something that says "touchpad"
TOUCHPAD_NAME="DELL0A69:00 0488:120A Touchpad"

# To find this for your computer, run `xinput list-props "$TOUCHPAD_NAME"` and
# look for something called "Tapping Enabled".
ENABLE_TAP_PROPERTY="libinput Tapping Enabled"

xinput set-prop "$TOUCHPAD_NAME" "$ENABLE_TAP_PROPERTY" 1
