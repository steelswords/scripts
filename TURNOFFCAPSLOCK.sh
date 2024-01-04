#!/bin/bash

# Check if xdotool command is available
if command -v xdotool &> /dev/null; then
    # Turn off Caps Lock
    xdotool key Caps_Lock
    echo "Caps Lock turned off."
else
    echo "xdotool command not found. This script requires X Window System environment."
fi

