#!/bin/bash
# Name:        numOfArguments.sh
# Author:      Tristan Andrus
# Description: Prints the number of arguments given.
################################################################################

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

echo $#
