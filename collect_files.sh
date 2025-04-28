#!/bin/bash
# test00: collect_files.sh: копирует файлы из input_dir в output_dir
# test01: max_depth исправлен.
# test02: добавлена отладочная печать
# test03: Без отладочной печати, но с безопасной обработкой имен
# test04: для грубины > max_depth
# test05: для грубины >= max_depth
# test06: перенесли max_depth в конец аргументов
# test07: улучшение понимаемости

# Должно быть как минимум два аргумента
if [ "$#" -lt 2 ]; then
    echo "Использовать так: $0 input_dir output_dir [--max_depth N]"
    exit 1
fi

# --max_depth
if [ "$3" == "--max_depth" ]; then
    max_depth="$4"
#    shift 2
# не двигаем, т.к. max_depth теперь в конце командной строки
else
    max_depth=""
fi

input_dir="$1"
output_dir="$2"

input_dir="${input_dir%/}"
output_dir="${output_dir%/}"

if [ ! -d "$input_dir" ]; then
    echo "Ошибка вызова: input_dir '$input_dir' - каталог не найден."
    exit 1
fi

mkdir -p "$output_dir"

copy_with_rename() {
    source_file_name="$1"
    dest_dir="$2"
    orgn_name="$(basename "$source_file_name")"

    if [[ "$orgn_name" == *.* ]]; then
        base="${orgn_name%.*}"
        ext="${orgn_name##*.}"
        if [ -z "$base" ]; then
            base="$orgn_name"
            ext=""
        fi
    else
        base="$orgn_name"
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

    cp "$source_file_name" "$dest_dir/$newname"
}

if [ -z "$max_depth" ]; then
    echo "max_depth не задан, выполняем линейное копирование"
    find "$input_dir" -type f -print0 |
    while IFS= read -r -d '' file; do
        copy_with_rename "$file" "$output_dir"
    done
else
    echo "выполняем копирование с обрезанием глубины до $max_depth"
    find "$input_dir" -type d -print0 |
    while IFS= read -r -d '' dir; do
        if [ "$dir" = "$input_dir" ]; then
            continue
        fi

        relocn_path="${dir#$input_dir/}"

        if [ -z "$relocn_path" ]; then
            deep=0
        else
            slashs_num=$(grep -o "/" <<< "$relocn_path" | wc -l)
            deep=$((slashs_num + 1))
        fi

        if [ "$deep" -ge "$max_depth" ]; then
            number=$((deep - max_depth + 1))
            new_relocn_path=$(echo "$relocn_path" | cut -d/ -f$((number+1))-)
        else
            new_relocn_path="$relocn_path"
        fi

        if [ -n "$new_relocn_path" ]; then
            mkdir -p "$output_dir/$new_relocn_path"
        else
            mkdir -p "$output_dir"
        fi
    done

    find "$input_dir" -type f -print0 |
    while IFS= read -r -d '' file; do
        relocn_path="${file#$input_dir/}"

        if [[ "$relocn_path" == */* ]]; then
            file_dir="${relocn_path%/*}"
            file_name="${relocn_path##*/}"
        else
            file_dir=""
            file_name="$relocn_path"
        fi

        if [ -z "$file_dir" ]; then
            deep=0
        else
            slashs_num=$(grep -o "/" <<< "$file_dir" | wc -l)
            deep=$((slashs_num + 1))
        fi

        if [ "$deep" -ge "$max_depth" ]; then
            number=$((deep - max_depth + 1))
            new_relocn_dir=$(echo "$file_dir" | cut -d/ -f$((number+1))-)
        else
            new_relocn_dir="$file_dir"
        fi

        if [ -n "$new_relocn_dir" ]; then
            full_dir="$output_dir/$new_relocn_dir"
        else
            full_dir="$output_dir"
        fi

        mkdir -p "$full_dir"
        copy_with_rename "$file" "$full_dir"
    done
fi

echo "Завершено выполненеи"
