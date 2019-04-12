#!/bin/bash
#
# Script to convert audio to alac and apply cover art from this file
#
# Arguments:
# - file name
#
# Requirements:
# - ffmpeg
# - mp4v2
#

usage() {
  echo "Script to convert audio files to alac (m4a container)."
  echo
  echo "Usage: $(basename $0) audio_file_names"
  echo

  exit 0
}

# Help handle
while getopts "h" optname; do
  case "$optname" in
    "h")
      usage
    ;;
  esac
done

# The argument must be provided
if [ $# -lt 1 ]; then
  echo
  echo "Provide at least one file name"
  echo
  usage
fi

# Conversion loop
for filename in "$@"; do

  alac_filename="${filename%.*}.m4a"
  ffmpeg -y -i "$filename" -acodec alac -vn "$alac_filename"

  pic_name="cover.mjpeg"
  ffmpeg -i "$filename" -map 0:$( \
    ffprobe \
      -loglevel quiet \
      -print_format json \
      -hide_banner \
      -select_streams v \
      -show_streams "$filename" | jq '.streams[] | if .tags.comment == "Cover (front)" then .index else empty end') "$pic_name" || if [ -e "$alac_filename" ]; then
        # if alac file exists we can safely remove source file and finish the script
        echo "No cover art I guess"
        rm "$filename"
        exit 0
      fi

  # If cover art was found apply it to alac file
  mp4art --add "$pic_name" "$alac_filename"
  rm "$pic_name"
  # Remove source file if dest file exists
  if [ -e "$alac_filename" ]; then
    rm "$filename"
  fi

done
