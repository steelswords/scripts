#!/usr/bin/env bash
# File:        achievement
# Author:      Tristan Andrus
# Description: Stores achievements at work for you in a text file, so you can retrieve
#              them later if need be.
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################

ACHIEVEMENTS_REPO_DIR="$HOME/.config/achievments"
ACHIEVEMENTS_FILE="$ACHIEVEMENTS_REPO_DIR/achievements.txt"

# Ensure ACHIEVEMENTS_REPO_DIR exists
if [ ! -d "$ACHIEVEMENTS_REPO_DIR" ]; then
    mkdir -p "$ACHIEVEMENTS_REPO_DIR"
    cd "$ACHIEVEMENTS_REPO_DIR"
    git init

    echo "Created $ACHIEVEMENTS_REPO_DIR"
    echo "Initialized git repository in $ACHIEVEMENTS_REPO_DIR"
    echo ""
    echo "Please add a remote to $ACHIEVEMENTS_REPO_DIR"
    echo "Enter remote URL: "
    read remote_url

    echo "${USER}'s Achievments" >> "$ACHIEVEMENTS_FILE"
    git add "$ACHIEVEMENTS_FILE"
    git commit -m "Initial commit"

    git remote add origin $remote_url
    git push -u origin master
    echo "Remote added and master branch pushed to origin"
fi

# Echo everything passed in as an argument to the achievements file
timestamp=$(date +"%Y-%m-%d %T")
echo "$timestamp: $@" >> "$ACHIEVEMENTS_FILE"
cd "$ACHIEVEMENTS_REPO_DIR"
git add "$ACHIEVEMENTS_FILE"
git commit -m "Added achievement"
git push

echo ""
echo "Congratulations on your achievement!"
echo "I have added it and synched it to the remote repository"
