#!/bin/bash
# Install applications and dev environment on clean Ubuntu install of latest LTS release.
# Authored by eggshell (Cullen Taylor)

set -e

# INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

  reporter "Installing ibmcloud tools"
  curl -sL https://ibm.biz/idt-installer | bash
}

main "$@"
