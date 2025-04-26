#!/bin/bash

# Проверка минимального количества аргументов
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
    exit 1
fi

# Инициализация переменных
max_depth=-1
input_dir=""
output_dir=""

# Разбор аргументов
if [ "$1" == "--max_depth" ]; then
    if [ "$#" -ne 4 ]; then
        echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
        exit 1
    fi
    max_depth=$2
    input_dir=$3
    output_dir=$4
else
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 [--max_depth N] /path/to/input_dir /path/to/output_dir"
        exit 1
    fi
    input_dir=$1
    output_dir=$2
fi

# Проверка существования входной директории
if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist"
    exit 1
fi

# Создание выходной директории
mkdir -p "$output_dir"

# Функция для генерации уникального имени файла
get_unique_filename() {
    local dest=$1
    local filename=$2
    local name="${filename%.*}"
    local ext="${filename##*.}"

    # Обработка файлов без расширения
    if [ "$name" == "$ext" ]; then
        ext=""
        name="$filename"
    else
        ext=".$ext"
    fi

    local counter=1
    local new_filename="${name}${ext}"
    
    while [ -e "$dest/$new_filename" ]; do
        new_filename="${name}${counter}${ext}"
        counter=$((counter + 1))
    done

    echo "$new_filename"
}

# Функция для копирования файлов с учетом глубины
copy_with_depth() {
    local src=$1
    local dest=$2
    local current_depth=$3
    local max_d=$4

    for item in "$src"/*; do
        if [ -f "$item" ]; then
            # Обработка файла
            filename=$(basename "$item")
            unique_name=$(get_unique_filename "$dest" "$filename")
            cp "$item" "$dest/$unique_name"
        elif [ -d "$item" ]; then
            # Обработка директории
            dirname=$(basename "$item")
            if [ "$max_d" -eq -1 ] || [ "$current_depth" -lt "$max_d" ]; then
                # Копируем с сохранением структуры
                new_dest="$dest/$dirname"
                mkdir -p "$new_dest"
                copy_with_depth "$item" "$new_dest" $((current_depth + 1)) "$max_d"
            else
                # Копируем содержимое с уменьшением глубины
                copy_with_depth "$item" "$dest" "$current_depth" "$max_d"
            fi
        fi
    done
}

# Запуск основной функции
copy_with_depth "$input_dir" "$output_dir" 0 "$max_depth"

echo "Я щас помру я уже не можу"
