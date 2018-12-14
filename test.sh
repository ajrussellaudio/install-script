#!/usr/bin/env bash

append_to_zshrc() {
  local text="$1" zshrc
  local skip_new_line="${2:-0}"

  if [ -w "$HOME/.zshrc.local" ]; then
    zshrc="$HOME/.zshrc.local"
  else
    zshrc="$HOME/.zshrc"
  fi

  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$zshrc"
    else
      printf "\n%s\n" "$text" >> "$zshrc"
    fi
  fi
}

create_folder_if_not_there() {
  local folder="$1"

  if ! [ -d "$folder" ]; then
    mkdir -p "$folder"
  fi
}

create_folder_and_shortcut() {
  local folder="$1" shortcut="$2"

  create_folder_if_not_there "$folder"
  append_to_zshrc "alias $shortcut=$folder"
}

create_folder_and_shortcut "here/Documents/test" "test"