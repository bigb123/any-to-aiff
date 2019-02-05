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

die() {
  echo "No coverart I guess."
  rm "$filename"
  exit 0
}

filename="$1"
alac_filename="${filename%.*}.m4a"
ffmpeg -y -i "$filename" -acodec alac -vn "$alac_filename"

pic_name="cover.mjpeg"
ffmpeg -i "$filename" -map 0:$( \
  ffprobe \
    -loglevel quiet \
    -print_format json \
    -hide_banner \
    -select_streams v \
    -show_streams "$filename" | jq '.streams[] | if .tags.comment == "Cover (front)" then .index else empty end') "$pic_name" || die

mp4art --add "$pic_name" "$alac_filename"
rm "$pic_name"
rm "$filename"
