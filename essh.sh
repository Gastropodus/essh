#!/bin/bash

CONFIG_FILE=""

declare -A CONFIG=(
    ["USER_NAME"]=""
)

show_help() {
    echo "Usage: $0 [-c=/path/to/config]"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c=*|--config=*)
            CONFIG_FILE="${1#*=}"
            shift
            ;;
        -c|--config)
            if [[ -n "$2" && "$2" != -* ]]; then
                CONFIG_FILE="$2"
                shift 2
            else
                echo "Error: Missing argument for $1"
                show_help
            fi
            ;;
#        -k|--key)
#            key_flag="True"
#            shift
#            ;;
        *)
            echo "Error: Invalid argument $1"
            show_help
            ;;
    esac
done

if [[ -n "$CONFIG_FILE" && ! -f "$CONFIG_FILE" ]]; then
    echo "Error: $CONFIG_FILE not a file"
    exit 1
else
    if [[ -n "$XDG_CONFIG_HOME" && -f "$XDG_CONFIG_HOME/essh/essh.conf" ]]; then
        CONFIG_FILE="$XDG_CONFIG_HOME/essh/essh.conf"
    elif [[ -f "$HOME/.config/essh/essh.conf" ]]; then
        CONFIG_FILE="$HOME/.config/essh/essh.conf"
    elif [[ -f "$HOME/.essh.conf" ]]; then
        CONFIG_FILE="$HOME/.essh.conf"
    elif [[ -f "/etc/essh/essh.conf" ]]; then
        CONFIG_FILE="/etc/essh/essh.conf"
    fi
fi

if [[ -n "$CONFIG_FILE" ]]; then
    shopt -s extglob

    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line##+([[:space:]])}"
        line="${line%%+([[:space:]])}"

        [[ -z "$line" ]] && continue

        key="${line%%=*}"
        key="${key##+([[:space:]])}"
        key="${key%%+([[:space:]])}"
        value="${line#*=}"
        value="${value##+([[:space:]])}"
        value="${value%%+([[:space:]])}"

        [[ -n "${CONFIG[$key]+1}" ]] && CONFIG["$key"]="$value"
    done < "$CONFIG_FILE"

    shopt -u extglob
fi

readarray -t servers < <(tsh ls | tail -n +3 | head -n -1)

list=$(for index in "${!servers[@]}"; do
    echo "[$index]: ${servers[$index]}" | awk '{gsub("⟵", ""); print $1 " " $2 " " $3}'
done)

last_server=$((${#servers[@]} - 1))

echo "$list" | column -t
read -rp "Please choose server to connect: " choosen_server

if [[ ! "$choosen_server" =~ ^[0-9]+$ ]]; then
    echo "Error: $choosen_server not a number"
    exit 1
fi

if [[ "$choosen_server" -gt "$last_server" ]]; then
    echo "Error: $choosen_server is out of range"
    exit 1
fi

server_domen=$(echo "${servers[$choosen_server]}" | awk '{print $1}')

if [[ ! -n "${CONFIG[USER_NAME]}" ]]; then
    read -rp "Please provide a user name: " "CONFIG[USER_NAME]"
    if [[ ! -n "${CONFIG[USER_NAME]}" ]]; then
	echo "Error: User name is empry"
	exit 0
    fi
fi

tsh ssh "${CONFIG[USER_NAME]}@$server_domen"
