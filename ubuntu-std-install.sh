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
  add-apt-repository -y universe
  add-apt-repository -y ppa:linrunner/tlp
}

function ensure_discord() {
  reporter "Installing discord"
  TEMP_DEB="$(mktemp)" &&
  wget -O "$TEMP_DEB" 'https://discordapp.com/api/download?platform=linux&format=deb' &&
  dpkg -i "$TEMP_DEB"
  rm -f "$TEMP_DEB"
}

function ensure_docker() {
  reporter "Installing docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
  apt update
  apt install -y docker-ce
  usermod -aG docker $(whoami)
}

function ensure_kubectl() {
  reporter "Installing kubectl"
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
  apt update
  apt install -y kubectl
}

function ensure_ohmyzsh() {
  reporter "Installing oh-my-zsh"
  CURRENT_USER=$(whoami)
  usermod -s /usr/bin/zsh $CURRENT_USER
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | grep -Ev 'chsh -s|env zsh')"
}

function ensure_owned_dirs() {
  reporter "Ensuring needed dirs are owned by current user"
  chown -R $(whoami):$(whoami) /usr/local/src
  chown -R $(whoami):$(whoami) /home/$(whoami)/.oh-my-zsh || :
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
  if [ -d "/home/$(whoami)/.oh-my-zsh" ]; then
    reporter "Backing up sunrise theme"
    mv /home/$(whoami)/.oh-my-zsh/themes/sunrise.zsh-theme \
       /home/$(whoami)/.oh-my-zsh/themes/sunrise.zsh-theme.old
  fi
}

function ensure_dotfiles() {
  reporter "Grabbing and stowing dotfiles"
  DOTFILES_REPO=https://gitlab.com/eggshell/dotfiles.git
  DOTFILES_DESTINATION=$HOME/dotfiles
  DOTFILES_BRANCH=master
  STOW_LIST="config git oh-my-zsh htop vim xscreensaver xorg zsh"

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
  apt update

  reporter "Installing apt packages from list"
  apt install -y $(awk '{ print $1 }' std_data/apt_packages.list)

  reporter "Installing pip packages from list"
  pip install -r server_data/pip_packages.list

  ensure_discord
  ensure_docker
  ensure_kubectl
  ensure_ohmyzsh
  ensure_owned_dirs
  ensure_zsh_syntax_highlighting
  remove_old_configs
  rename_ohmyzsh_theme
  ensure_dotfiles

  reporter "Installing ibmcloud tools"
  curl -sL https://ibm.biz/idt-installer | bash

  reporter "Generating user RSA keys"
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
}

main "$@"
