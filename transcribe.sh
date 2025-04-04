#!/usr/bin/env bash
# File:        transcribe
# Author:      Tristan Andrus
# Description: Toggles transcription through BlahST, whisper.cpp, and xdotool
# Requirements: mpg123 sox cmake xsel xdotool ... more...
################################################################################

set -o errexit   # Abort on nonzero exitstatus
set -o nounset   # Abort on unbound variable
set -o pipefail  # Don't hide errors within pipes

trap "echo 'An error occurred! Quitting mid-script!'" ERR

# Colors for more visual statuses
_RED_TEXT='\033[31m'
_GREEN_TEXT='\033[32m'
_YELLOW_TEXT='\033[33m'
_BLUE_TEXT='\033[34m'
_CLEAR_TEXT='\033[0m'
_BOLD_TEXT='\033[1m'

function echo_warning() { echo -e "${_YELLOW_TEXT}$*${_CLEAR_TEXT}"; }
function echo_error()   { echo -e "${_RED_TEXT}$*${_CLEAR_TEXT}";    }
function echo_success() { echo -e "${_GREEN_TEXT}$*${_CLEAR_TEXT}";  }
function echo_status()  { echo -e "${_BLUE_TEXT}$*${_CLEAR_TEXT}";   }

# Uncomment to debug
# set -x

################################################################################
TRANSCRIBE_TEMP_RECORD_FILE=/tmp/transcriptioninput.wav

function die_loudly() {
    error_line="$1"
    echo_error "Something bad happened while running line $error_line. Quitting now."
    exit 10
}



function setup() {
    base_dir="$HOME/Repos/notmine2"
    install_dir="$HOME/.local/whisper.cpp"

    mkdir -p "$base_dir"
    cd ~/Repos/notmine2 || die_loudly $LINENO

    # Set up whisper
    git clone git@github.com:ggerganov/whisper.cpp.git --depth 1 ||:
    cd whisper.cpp || die_loudly $LINENO

    cmake -B build
    cmake --build build --config Release
    cmake --install build --prefix "$install_dir"

    # Just like everything in AI, things move so fast and break all. The. Time.
    # BlahST references 'main' and 'server' instead of 'stream' and 'whisper-server'
    # Copy these over as what it expects.
    cp build/bin/main "$install_dir/bin/main"
    cp build/bin/whisper-server "$install_dir/bin/server"

    # Install models
    bash ./models/download-ggml-model.sh small
    cp -r models "$base_dir"

    ############################################################################
    # Install BlahST
    cd "$base_dir"
    git clone git@github.com:QuantiusBenignus/BlahST.git
    cd BlahST || die_loudly $LINENO

    echo "You will need to modify the USER CONFIGURATION BLOCK. Understand?"
    user_input=""
    read -r user_input

    $EDITOR wsi

    echo "Now installing BlahST"

    $SHELL ./install-wsi
}


function is_transcription_listening() {
    if [[ -f "$TRANSCRIBE_TEMP_RECORD_FILE" ]]; then
        return 0
    fi
    return 1
}

function play_sound() {
    mpg123 "$@" &> /dev/null
}

function turn_transcription_on() {
    echo "Turning transcription on"
    play_sound media/incoming2.mp3

    touch "$TRANSCRIBE_TEMP_RECORD_FILE"
    rec -q -t wav $TRANSCRIBE_TEMP_RECORD_FILE rate 16k 2>/dev/null &
}

function transcribe_audio_file() {
    MODEL="$HOME/.local/whisper.cpp/models/ggml-base.en.bin"
    NUM_THREADS=$(( $(nproc) - 1 ))
    WHISPER_EXE=whisper-cli

    str="$("$WHISPER_EXE" -t $NUM_THREADS -nt -m "$MODEL" -f "$TRANSCRIBE_TEMP_RECORD_FILE" 2>/dev/null)" 
    echo "------------------------------- Result:"
    echo "$str"
    echo "---------------------------------------"
}

function turn_transcription_off() {
    echo "Turning transcription off"
    play_sound media/ding.mp3
    pkill --signal 2 rec ||:
    transcribe_audio_file
    #echo "This is what you recorded."
    #play "$TRANSCRIBE_TEMP_RECORD_FILE"
    # TODO: This is not concurrency safe. Need a lock to avoid weirdness with rapid presses
    rm "$TRANSCRIBE_TEMP_RECORD_FILE"
}

function toggle_transcription() {
    if is_transcription_listening; then
        turn_transcription_off
    else
        turn_transcription_on
    fi
}


################################################################################
# Main script body
################################################################################
case $# in
    0)
        # Default behavior is to toggle
        echo "Toggling transcription"
        toggle_transcription
        ;;
    1)
        if [[ $1 == 'setup' ]]; then
            setup
            exit 0
        else
            print_usage
            exit 0
        fi
        ;;
    *)
        print_usage
        exit 2
        ;;
esac


