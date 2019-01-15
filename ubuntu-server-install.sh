#!/bin/bash
# Install applications and dev environment on clean Ubuntu install of latest LTS release.
# Authored by eggshell (Cullen Taylor)

set -e

# Turn comments into literal programming, including output during execution.
function reporter() {
  MESSAGE="$1"
  shift
  echo
  echo "${MESSAGE}"
  for (( i=0; i<${#MESSAGE}; i++ )); do
      echo -n '-'
  done
  echo
}

function check_for_internet() {
  reporter "Confirming internet connection"
  if [[ ! $(curl -Is http://www.google.com/ | head -n 1) =~ "200 OK" ]]; then
    echo "Your Internet seems broken. Press Ctrl-C to abort or enter to continue."
    read
  else
    echo "Connection successful"
  fi
}

function ensure_ohmyzsh() {
  reporter "Installing oh-my-zsh"
  CURRENT_USER=$(whoami)
  sudo usermod -s /usr/bin/zsh $CURRENT_USER
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | grep -Ev 'chsh -s|env zsh')"
}

function ensure_owned_dirs() {
  reporter "Ensuring needed dirs are owned by current user"
  sudo chown -R $(whoami):$(whoami) /usr/local/src
  sudo chown -R $(whoami):$(whoami) /home/$(whoami)/.oh-my-zsh
}

function ensure_zsh_syntax_highlighting() {
  reporter "Cloning zsh-syntax-highlighting"
  SYNTAX_DIR=/usr/local/src/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${SYNTAX_DIR}
}

function remove_old_configs() {
  reporter "Removing old config files"
  OLD_CONFIGS=".gitconfig .zshrc .vimrc .vim"
  for CONFIG in ${OLD_CONFIGS}; do
      rm -rf $HOME/${CONFIG}
  done
}

function rename_ohmyzsh_theme() {
  mv /home/$(whoami)/.oh-my-zsh/themes/sunrise.zsh-theme \
     /home/$(whoami)/.oh-my-zsh/themes/sunrise.zsh-theme.old
}

function ensure_dotfiles() {
  reporter "Grabbing and stowing dotfiles"
  DOTFILES_REPO=https://github.com/eggshell/dotfiles.git
  DOTFILES_DESTINATION=$HOME/dotfiles
  DOTFILES_BRANCH=master
  STOW_LIST="oh-my-zsh git htop vim zsh"

  git clone ${DOTFILES_REPO} ${DOTFILES_DESTINATION}
  cd ${DOTFILES_DESTINATION}
  git checkout ${DOTFILES_BRANCH}
  for app in ${STOW_LIST}; do
      stow ${app}
  done
  cd ${HOME}
}

function main() {
  check_for_internet

  reporter "Updating apt cache"
  sudo apt update

  reporter "Installing apt packages from list"
  sudo apt install -y $(awk '{ print $1 }' server_data/apt_packages.list)

  ensure_ohmyzsh
  ensure_owned_dirs
  ensure_zsh_syntax_highlighting
  remove_old_configs
  rename_ohmyzsh_theme
  ensure_dotfiles
}

main "$@"
