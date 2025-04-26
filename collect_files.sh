#!/bin/bash

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 [--max_depth N] <input_dir> <output_dir>"
    exit 1
fi

MAX_DEPTH=""
INPUT_DIR=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --max_depth)
            shift
            MAX_DEPTH=$1
            shift
            ;;
        *)
            if [[ -z "$INPUT_DIR" ]]; then
                INPUT_DIR="$1"
            elif [[ -z "$OUTPUT_DIR" ]]; then
                OUTPUT_DIR="$1"
            else
                echo "Unexpected argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Input directory does not exist: $INPUT_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

copy_file_with_suffix() {
    local src_file="$1"
    local dest_dir="$2"

    mkdir -p "$dest_dir"

    local filename=$(basename "$src_file")
    local name="${filename%.*}"
    local ext="${filename##*.}"

    if [[ "$name" == "$ext" ]]; then
        ext=""
    else
        ext=".$ext"
    fi

    local dest_file="$dest_dir/$name$ext"
    local counter=1

    while [[ -e "$dest_file" ]]; do
        dest_file="$dest_dir/${name}${counter}${ext}"
        ((counter++))
    done

    cp "$src_file" "$dest_file"
}

truncate_path() {
    local path="$1"
    local depth="$2"

    IFS='/' read -ra parts <<< "$path"
    local result=""

    for ((i=0; i<depth && i<${#parts[@]}; i++)); do
        if [[ -n "${parts[$i]}" ]]; then
            result="$result/${parts[$i]}"
        fi
    done

    echo "${result#/}"
}

find "$INPUT_DIR" -mindepth 1 | while IFS= read -r item; do
    rel_path="${item#$INPUT_DIR/}"
    depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
    depth=$((depth + 1))

    if [[ -z "$MAX_DEPTH" ]]; then
        if [[ -f "$item" ]]; then
            copy_file_with_suffix "$item" "$OUTPUT_DIR"
        fi
    else
        if [[ -d "$item" ]]; then
            if [[ "$depth" -lt "$MAX_DEPTH" ]]; then
                mkdir -p "$OUTPUT_DIR/$rel_path"
            elif [[ "$depth" -eq "$MAX_DEPTH" ]]; then
                mkdir -p "$OUTPUT_DIR/$rel_path"
            else
                truncated_rel_path=$(truncate_path "$rel_path" "$MAX_DEPTH")
                mkdir -p "$OUTPUT_DIR/$truncated_rel_path"
            fi
        elif [[ -f "$item" ]]; then
            if [[ "$depth" -le "$MAX_DEPTH" ]]; then
                dest_dir="$OUTPUT_DIR/$(dirname "$rel_path")"
            else
                truncated_rel_path=$(truncate_path "$(dirname "$rel_path")" "$MAX_DEPTH")
                dest_dir="$OUTPUT_DIR/$truncated_rel_path"
            fi
            copy_file_with_suffix "$item" "$dest_dir"
        fi
    fi
done

echo "Завершено"
