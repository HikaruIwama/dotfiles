#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_file="$root/zsh/.zshrc"
target="$HOME/.zshrc"

if ! command -v zsh >/dev/null 2>&1; then
  if ! command -v apt-get >/dev/null 2>&1; then
    printf 'apt-get is required to install zsh.\n' >&2
    exit 1
  fi
  sudo apt-get update
  sudo apt-get install -y zsh
fi

if [[ -L "$target" && "$(readlink -f -- "$target")" == "$source_file" ]]; then
  printf 'Already linked: %s\n' "$target"
  exit 0
fi

if [[ -e "$target" || -L "$target" ]]; then
  backup="$target.before-dotfiles-$(date +%Y%m%d%H%M%S)-$$"
  mv -- "$target" "$backup"
  printf 'Saved existing config: %s\n' "$backup"
fi

ln -s -- "$source_file" "$target"
printf 'Linked %s -> %s\n' "$target" "$source_file"
