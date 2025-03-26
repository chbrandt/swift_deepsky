#!/usr/bin/env bash

usage() {
  echo ""
  echo "Usage: $0 -i input_file -o output_file"
  echo ""
  exit 1
}

# Parse command line options
while getopts "i:o:" opt; do
  case $opt in
    i) input_file="$OPTARG" ;;
    o) output_file="$OPTARG" ;;
    \?) usage ;;
  esac
done

# Set default values if not provided
if [ -z "$input_file" ]; then
    echo "Error: input_file is not defined or empty"
    usage
fi
if [ -z "$output_file" ]; then
    echo "Error: output_file is not defined or empty"
    usage
fi

head -n200 "$input_file" \
    | grep "^line" \
    | cut -d " " -f3- \
    | sed "s/ /|/g" \
    | tr '[:lower:]' '[:upper:]' \
    > "$output_file"

perl -lne 'print if((/<DATA>/../<END>/) && !(/<DATA>/||/<END>/))' "$input_file"\
    >> "$output_file"

