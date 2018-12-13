#!/usr/bin/env bash

# Adapted from:
# https://gist.github.com/codeinthehole/26b37efa67041e1307db
# and
# https://github.com/codeclan/laptop/blob/master/mac

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

  if [ -d "$folder" ]; then
    if ! [ -r "$folder" ]; then
      sudo chown -R "$LOGNAME:admin" "$folder"
    fi
  else
    sudo mkdir -p "$folder"
    sudo chflags norestricted "$folder"
    sudo chown -R "$LOGNAME:admin" "$folder"
  fi
}

echo "Starting bootstrapping"

# Recite the Xcode incantation

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

# Install Zsh
brew install zsh zsh-completions
chsh -s $(which zsh)

echo "Current shell:" $SHELL

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Configure Git

# Install NodeJS

# Install iTerm2
brew cask install iterm2

# Install Chrome
brew cask install google-chrome

# Install VS Code and Settings Sync
brew cask install visual-studio-code
code --install-extension shan.code-settings-sync
