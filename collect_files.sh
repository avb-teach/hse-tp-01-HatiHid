#!/bin/bash
# test00: collect_files.sh: копирует файлы из input_dir в output_dir
# test01: max_depth исправлен.
# test02: добавлена отладочная печать
# test03: Без отладочной печати, но с безопасной обработкой имен
# test04: для грубины > max_depth
# test05: для грубины >= max_depth
# test06: перенесли max_depth в конец аргументов

# Должно быть как минимум два аргумента
if [ "$#" -lt 2 ]; then
    echo "Использовать так: $0 input_dir output_dir [--max_depth N]"
    exit 1
fi

# --max_depth
if [ "$3" == "--max_depth" ]; then
    max_depth="$4"
#    shift 2
# не двигаем, т.к. max_depth теперь в конце
else
    max_depth=""
fi

input_dir="$1"
output_dir="$2"

input_dir="${input_dir%/}"
output_dir="${output_dir%/}"

if [ ! -d "$input_dir" ]; then
    echo "Error: input_dir '$input_dir' not found or not a directory."
    exit 1
fi

mkdir -p "$output_dir"

copy_with_rename() {
    src_file="$1"
    dest_dir="$2"
    base_name="$(basename "$src_file")"

    if [[ "$base_name" == *.* ]]; then
        base="${base_name%.*}"
        ext="${base_name##*.}"
        if [ -z "$base" ]; then
            base="$base_name"
            ext=""
        fi
    else
        base="$base_name"
        ext=""
    fi

    if [ -z "$ext" ]; then
        newname="$base"
    else
        newname="$base.$ext"
    fi

    count=1
    while [ -e "$dest_dir/$newname" ]; do
        if [ -z "$ext" ]; then
            newname="${base}${count}"
        else
            newname="${base}${count}.$ext"
        fi
        count=$((count + 1))
    done

    cp "$src_file" "$dest_dir/$newname"
}

if [ -z "$max_depth" ]; then
    find "$input_dir" -type f -print0 |
    while IFS= read -r -d '' file; do
        copy_with_rename "$file" "$output_dir"
    done
else
    find "$input_dir" -type d -print0 |
    while IFS= read -r -d '' dir; do
        if [ "$dir" = "$input_dir" ]; then
            continue
        fi

        rel_path="${dir#$input_dir/}"

        if [ -z "$rel_path" ]; then
            levels=0
        else
            slash_count=$(grep -o "/" <<< "$rel_path" | wc -l)
            levels=$((slash_count + 1))
        fi

        if [ "$levels" -ge "$max_depth" ]; then
            drop=$((levels - max_depth + 1))
            new_rel_path=$(echo "$rel_path" | cut -d/ -f$((drop+1))-)
        else
            new_rel_path="$rel_path"
        fi

        if [ -n "$new_rel_path" ]; then
            mkdir -p "$output_dir/$new_rel_path"
        else
            mkdir -p "$output_dir"
        fi
    done

    find "$input_dir" -type f -print0 |
    while IFS= read -r -d '' file; do
        rel_path="${file#$input_dir/}"

        if [[ "$rel_path" == */* ]]; then
            file_dir="${rel_path%/*}"
            file_name="${rel_path##*/}"
        else
            file_dir=""
            file_name="$rel_path"
        fi

        if [ -z "$file_dir" ]; then
            levels=0
        else
            slash_count=$(grep -o "/" <<< "$file_dir" | wc -l)
            levels=$((slash_count + 1))
        fi

        if [ "$levels" -ge "$max_depth" ]; then
            drop=$((levels - max_depth + 1))
            new_rel_dir=$(echo "$file_dir" | cut -d/ -f$((drop+1))-)
        else
            new_rel_dir="$file_dir"
        fi

        if [ -n "$new_rel_dir" ]; then
            target_dir="$output_dir/$new_rel_dir"
        else
            target_dir="$output_dir"
        fi

        mkdir -p "$target_dir"
        copy_with_rename "$file" "$target_dir"
    done
fi

echo "Завершено выполненеи"
