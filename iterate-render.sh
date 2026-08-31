#!/usr/bin/env bash
# File:        iterate-render.sh
# Author:      Tristan Andrus
# Description: Given an input file, sets up watchers and constantly re-renders
#              or refreshes the file
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Uncomment to debug
# set -x

################################################################################
INPUT_FILE="${1:-}"
OUTPUT_FILE="output.png"

get_file_extension() {
    # Remove prefix of everything before '.' character.
    # ## = Remove *longest* prefix possible
    echo "${1##*.}"
}


# Runs the "initial command, i.e. opens a webbrowser." Sometimes this is the same
# as the `run_refresh_command` 
run_initial_command() {
    filetype="$(get_file_extension "$INPUT_FILE")"
    case "$filetype" in
        gv|grafviz|graphviz|dot)
            echo "-> Graphviz/dot input file detected."
            OUTPUT_FILE="output.png"
            dot -Tpng "$INPUT_FILE" -o "$OUTPUT_FILE"
            feh --auto-reload "OUTPUT_FILE" &
            ;;
        puml|plantuml)
            OUTPUT_FILE=output.svg
            return { cat "$INPUT_FILE" | plantuml --svg -pipe > "$OUTPUT_FILE" }
            ;;
        *)
            echo "-> Unknown file type. Quitting."
            exit 1
            ;;
    esac
    return 0
}

run_refresh_command() {
    filetype="$(get_file_extension "$INPUT_FILE")"
    case "$filetype" in
        gv|grafviz|graphviz|dot)
            return dot -Tpng "$INPUT_FILE" -o "$OUTPUT_FILE" 
            ;;
        puml|plantuml)
            OUTPUT_FILE=output.svg
            return { cat "$INPUT_FILE" | plantuml --svg -pipe > "$OUTPUT_FILE"}
            ;;
        *)
            echo "-> Unknown file type. Quitting."
            exit 1
            ;;
    esac
    return 0
}

function test_get_extension()
{
    function do_single_test() {
        full_file="$1"
        extension="$2"
        printf " -> TEST: get_file_extension for %s:" "$full_file"
        function_output=$(get_file_extension "$full_file")
        if [[ $function_output == $extension ]]; then
            printf " PASS\n"
        else
            printf "FAIL\n"
            echo "Expected \"$extension\". Got \"$function_output\""
            exit 2
        fi
    }

    do_single_test "test.txt" "txt"
    do_single_test 'one.more.time.data' 'data'
    do_single_test '/something/.txt/one/taylor/swift.phone.number' 'number'

    exit 0
}

#test_get_extension
#exit 0

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <input file>"
    exit 2
fi


run_initial_command
while true;
do
    echo "Waiting for changes to $INPUT_FILE"
    inotifywait -q "$INPUT_FILE"
    echo "Regenerating $(get_file_extension "$OUTPUT_FILE") file."
    while ! run_refresh_command ; do
        echo "Couldn't refresh render. Trying again soon."
        sleep 0.5
    done
done
