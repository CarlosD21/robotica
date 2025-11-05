#!/bin/sh
printf '\033c\033]0;%s\a' robotica
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ejecutable.x86_64" "$@"
