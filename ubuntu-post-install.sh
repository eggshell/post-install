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

function ensure_repos() {
  reporter "Ensuring universe and tlp repos are added"
  sudo add-apt-repository -y universe
  sudo add-apt-repository -y ppa:linrunner/tlp
}

function ensure_discord() {
  reporter "Installing discord"
  TEMP_DEB="$(mktemp)" &&
  wget -O "$TEMP_DEB" 'https://discordapp.com/api/download?platform=linux&format=deb' &&
  sudo dpkg -i "$TEMP_DEB"
  rm -f "$TEMP_DEB"
}

function ensure_docker() {
  reporter "Installing docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
  sudo apt update
  sudo apt install -y docker-ce
}

function ensure_kubectl() {
  reporter "Installing kubectl"
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt update
  sudo apt install -y kubectl
}

function ensure_ohmyzsh() {
  reporter "Installing oh-my-zsh"
  CURRENT_USER=$(whoami)
  sudo usermod -s /usr/bin/zsh $CURRENT_USER
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | grep -Ev 'chsh -s|env zsh')"
}

function ensure_owned_dirs() {
  reporter "Ensuring needed dirs are owned by current user"
  sudo chown -R $(whoami) /usr/local/src
}

function ensure_zsh_syntax_highlighting() {
  reporter "Cloning zsh-syntax-highlighting"
  SYNTAX_DIR=/usr/local/src
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${SYNTAX_DIR}
}

function remove_old_configs() {
  reporter "Removing old config files"
  OLD_CONFIGS=".zshrc .vimrc .vim .gitconfig"
  for CONFIG in ${OLD_CONFIGS}; do
      rm -rf $HOME/${CONFIG}
  done
}

function ensure_dotfiles() {
  reporter "Grabbing and stowing dotfiles"
  DOTFILES_REPO=https://github.com/eggshell/dotfiles.git
  DOTFILES_DESTINATION=$HOME/dotfiles
  DOTFILES_BRANCH=master
  STOW_LIST="config git htop vim xscreensaver xorg zsh"

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
  ensure_repos

  reporter "Updating apt cache"
  sudo apt update

  reporter "Installing apt packages from list"
  sudo apt install -y $(awk '{ print $1 }' data/apt_packages.list)

  ensure_discord
  ensure_docker
  ensure_kubectl
  ensure_ohmyzsh
  ensure_owned_dirs
  ensure_zsh_syntax_highlighting
  remove_old_configs
  ensure_dotfiles

  reporter "Installing ibmcloud tools"
  curl -sL https://ibm.biz/idt-installer | bash

  reporter "Generating user RSA keys"
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
}

main "$@"
