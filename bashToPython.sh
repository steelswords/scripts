#!/bin/bash
# Name:        bashToPython.sh
# Author:      Tristan Andrus
# Description: Converts command given as arguments to a python
#              subprocess command and copies it to the clipboard
################################################################################
# TODO: Nice: I thought about getting this to operate on the last given command
# if it wasn't given any arguments. You know, run the command you want and then
# run this script immediately afterward. But to do that, I'd have to read from a
# common history file, check if the default shell is zsh and read from that,
# but that seems like a lot of work for a 1 s improvement on a tool I won't use every day.

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

if [[ $# -eq 0 ]]
then
    echo "Usage: $0 <command> <you> <want> <to> <call> <in> <python>"
else
    bashCommand="$*"
fi

echo "Number of parts/words in input command: $(numOfArguments.sh $bashCommand)"

pythonResult="result = subprocess.run(["
for part in $bashCommand
do
    pythonResult="${pythonResult}\"$part\", "
    # TODO: prettify the ending
done
pythonResult="${pythonResult}])"

# Print it
echo "$pythonResult"

# And clip it
echo -n "$pythonResult" | xclip -sel clip -i
