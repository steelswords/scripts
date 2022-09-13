#!/bin/bash
# Name:        pinThisSong.sh
# Author:      Tristan Andrus
# Description: Grabs the title, artist, and album of the currently playing song
#              and appends it to a CSV file so you can buy it later.
################################################################################

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

songListFile="$HOME/songs-to-buy.csv"

# If file does not exist, write the header to the file
if [[ ! -a "$songListFile" ]]
then
    echo "Title, Artist, Album" > "$songListFile"
fi

# title, artist, album

playerctl metadata | awk '/xesam:title /{printf $3 ", " }' >> "$songListFile"
playerctl metadata | awk '/xesam:album /{printf $3 ", " }' >> "$songListFile"
playerctl metadata | awk '/xesam:albumArtist /{printf $3 }' >> "$songListFile"
echo "" >> "$songListFile"
