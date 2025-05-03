#!/usr/bin/env bash

set -eu -o pipefail

ERROR_TAG="rotating_light"

# Lower level send command
function notify() {
	tags="${1:-}"
	title="${2:-}"
	priority="${3:-}"
	message="${4:-}"

	# Send log file if tags contains rotating_light
	commonCurlArgs=(
		"-H" "Authorization: Bearer tk_pkbrcm68n02mb8cpbxzgomdkjxwoy"
		"-H" "Tags: $tags" 
		"-H" "Title: $title" 
		"-H" "Priority: $priority" 
	)

    echo "-> Sending notification with message $message"
    curl "${commonCurlArgs[@]}" \
        -d "$message" \
        https://nuntia.luthadel-artificers.duckdns.org/backups
}

trap 'notify "$ERROR_TAG" "ERROR Backing up deiopeaii" "high" "Check the logs"' ERR
function human_readable_time_taken() {
    seconds="$1"

    hours=$(( $seconds / 60 / 60 ))
    minutes=$(( $seconds / 60 - ( $hours * 60 ) ))
    seconds=$(( $seconds % 60 ))

    if (( $hours < 1 )); then hours=0; fi
    if (( $minutes < 1)); then minutes=0; fi
    if (( $seconds < 1)); then seconds=0; fi

    printf "%d:%02d:%02d" "$hours" "$minutes" "$seconds"
}

function process_file() {
    file="$1"
    new_file="$2"

    if [[ ! -e $file ]]; then
        notify "$ERROR_TAG" "Error in recoding. Could not recode $1 to $2" "high" "Invalid file names"
        exit 3
    fi
    
    start_time=$(date +%s)
    /home/tristan/recode.sh "$1" "$2"
    sleep 3
    done_recode_time=$(date +%s)

    size_of_orig=$( stat --printf="%s" "$1" )
    size_of_new=$( stat --printf="%s" "$2" )

    bytes_saved=$(( $size_of_orig - $size_of_new ))
    mib_saved=$( echo "scale=3; $bytes_saved / 1024 / 1024" | bc )

    echo "Saved $mib_saved MiB between the two"
    if [[ $( echo "$mib_saved > 0" | bc) == "1" ]]; then
        echo "Deleting the original file."
        shred -vuz "$file"
        sleep 2
    fi

    echo "Done recoding!"

    percent_saved=$( echo "scale=2; $bytes_saved / $size_of_orig " | bc )
    done_shred_time=$(date +%s)
    time_taken=$(human_readable_time_taken $(( $done_shred_time - $start_time )) )

    notify "wastebasket" "$mib_saved MiB Saved Recoding" "low" "$new_file was compressed $percent_saved %. The original has been rm-ed. The total process took $time_taken."

}

process_file 'BigVideo.mkv' 'SmallVideo.mkv'
