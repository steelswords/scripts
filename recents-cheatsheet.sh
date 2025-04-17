#!/usr/bin/env bash
# File:        recents-cheatsheet
# Author:      Tristan Andrus
# Description: This script pops open a window with the most recent additions I've
#              added to my poweruser toolbox. This makes it easier to say, "I know
#              I added a shortcut for <xyz> recently... What was that again?
#              Similar to the :Cheatsheet command I baked into my vim config
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

# This is cool! Apparently there is such a thing as pango markup, which lets you
# mark up text for GTK windows right in the string!
RECENTS="<tt>
Alt+Shift+I  <b>vimit</b>           Open nvim, paste saved contents into text input
Ctrl+Insert  <b>transcribe.sh</b>   Toggle transcription and pasting into current text input
pass         <b>pass</b>            Cli password manager
nnn          <b>nnn</b>             Tui file manager
</tt>
"

# Inspired shamelessly by BlahST/wsi by QuantiusBenignus
#Notification code, prefers zenity, then notify-send, (which should be available across
#most distributions, in package libnotify or libnotify-bin), KDE fallback is kdialog:
desknote() {
    local title="$1"
    local message="$2"

    if command -v zenity &> /dev/null; then
        zenity --info --no-wrap --title="$title" --text="$message"
    else
        echo "Notification Message: $message" >&2
        echo "Please install zenity to use desktop alerts." >&2
        echo "You can install either using your package manager, e.g.:" >&2
        echo "  sudo apt-get install zenity" >&2
        echo "  sudo yum install zenity" >&2
        echo "  sudo pacman -S zenity, etc." >&2
    fi
}

desknote "Cheatsheet" "$RECENTS"
