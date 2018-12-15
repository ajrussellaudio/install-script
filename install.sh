#!/bin/bash

# Adapted from:
# https://gist.github.com/codeinthehole/26b37efa67041e1307db
# and
# https://github.com/codeclan/laptop/blob/master/mac
# and
# https://github.com/mathiasbynens/dotfiles/blob/master/.macos

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

##############################################

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Starting bootstrapping"

# Recite the Xcode incantation

xcode-select -p 2>/dev/null
return_code=$?

while [ $return_code -eq 2 ]
do
  echo "\033[1;31mApple's Xcode Developer Tools are not installed!\033[0m"
  echo "\033[1;31mPlease install them through the dialog box before continuing with running this installation script.\033[0m"
  echo "Many of the tools used in this script will not work without the Xcode developer tools"
  echo "Opening 'Install Command Line Developer Tools'"
  xcode-select --install 1>/dev/null
  echo "Press enter to try again once Xcode developer tools are installed"
  read input
  xcode-select -p
  return_code=$?
done

if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

if [ ! -f "$HOME/.zshrc" ]; then
  touch "$HOME/.zshrc"
fi

append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing Zsh and Oh-My-Zsh..."
PACKAGES=(
  zsh
  zsh-completions
  python3
)
brew install ${PACKAGES[@]}

# Install Oh My Zsh in subshell
(sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)")

# Install NodeJS via NVM
sh -c "$(curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh)"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install node

echo "Installing cask apps..."
CASKS=(
  avast-security
  iterm2
  google-chrome
  spotify
  visual-studio-code
)
brew cask install ${CASKS[@]}

echo "Installing fonts..."
FONTS=(
  font-source-code-pro
  font-source-code-pro-for-powerline
)
brew tap homebrew/cask-fonts
brew cask install ${FONTS[@]}

create_folder_if_not_there "$HOME/Documents/settings/iterm"

# Download iTerm settings
(cd "$HOME/Documents/settings/iterm" && curl -O https://gist.githubusercontent.com/ajrussellaudio/f86857214c21199d703b822cb2e91d53/raw/f68fe163e7ac1b55c60d98ea1fc75eb472792bfd/com.googlecode.iterm2.plist)

# Install VS Code extensions
code --install-extension shan.code-settings-sync

# Install Spaceship prompt
npm install -g spaceship-prompt

echo "Creating folders and shortcuts..."
create_folder_and_shortcut "$HOME/Documents/working" "work"
create_folder_and_shortcut "$HOME/Documents/learning" "learn"
create_folder_and_shortcut "$HOME/Documents/playground" "play"
create_folder_and_shortcut "$HOME/Documents/open-source" "oss"

append_to_zshrc 'alias nuke="rm -rf node_modules && rm package-lock.json && npm install"'
append_to_zshrc 'alias cra="npx create-react-app ."'
append_to_zshrc 'alias co="code . -r"'

# Configure Git
npx git-setup

echo "Globally ignoring .DS_Store files..."
echo .DS_Store >> ~/.gitignore_global

echo "Setting up macOS preferences..."
# enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable “natural” (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Use scroll gesture with the Ctrl (^) modifier key to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
# Follow the keyboard focus while zoomed in
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

# Stop iTunes from responding to the keyboard media keys
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
function setScreenshotLocation() {
  local folder=$1
  mkdir "$folder"
  defaults write com.apple.screencapture location -string "$folder"
}
setScreenshotLocation "${HOME}/Desktop/Screenshots"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Don’t show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Disable the sensitive Chrome backswipe on trackpad
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
killall "Google Chrome" &> /dev/null

# TODO:
# - Set three-finger drag

echo "Done! Now start iTerm..."
