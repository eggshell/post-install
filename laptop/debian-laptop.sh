#!/bin/bash
# Install applications and dev environment on clean Debian (stretch) install.
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

function ensure_dependencies() {
  apt update -qq
  apt install -yqq apt-transport-https curl gnupg2 sudo
}

function ensure_eggshell() {
  useradd eggshell
  usermod -aG sudo eggshell
  mkdir -p /home/eggshell
  chown -R eggshell:eggshell /home/eggshell
  bash -c "echo '\neggshell ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
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

function ensure_apt_sources() {
  reporter "Ensuring apt sources"

  # Ensure desired apt sources list
  cat data/sources.list > /etc/apt/sources.list

  # Ensure default release is stable
  bash -c "echo -e '\n// default release should be stable\nAPT::Default-Release \"stable\";' >> /etc/apt/apt.conf.d/70debconf"

  # kubectl
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
}

function ensure_ohmyzsh() {
  reporter "Installing oh-my-zsh"
  CURRENT_USER=eggshell
  usermod -s /usr/bin/zsh $CURRENT_USER
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | grep -Ev 'chsh -s|env zsh')"
}

function ensure_owned_dirs() {
  reporter "Ensuring needed dirs are owned by current user"
  chown -R eggshell:eggshell /usr/local/src
  chown -R eggshell:eggshell /home/eggshell
}

function ensure_zsh_syntax_highlighting() {
  reporter "Cloning zsh-syntax-highlighting"
  SYNTAX_DIR=/usr/local/src/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${SYNTAX_DIR}
}

function remove_old_configs() {
  reporter "Removing old config files"
  OLD_CONFIGS=".gitconfig .zshrc .vimrc .vim .oh-my-zsh/themes/sunrise.zsh-theme"
  for CONFIG in ${OLD_CONFIGS}; do
      rm -rf $HOME/${CONFIG}
  done
}

function ensure_dotfiles() {
  reporter "Grabbing and stowing dotfiles"
  DOTFILES_REPO=https://gitlab.com/eggshell/dotfiles.git
  DOTFILES_DESTINATION=/home/eggshell/dotfiles
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

function ensure_xorg_conf() {
  rm /home/eggshell/xorg.conf
  cp -f /home/eggshell/dotfiles/xorg/xorg.conf /etc/X11/xorg.conf
}

function ensure_firefox() {
  apt install -yt sid firefox
  apt purge firefox-esr -y
}

function ensure_golang() {
  wget https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.12.4.linux-amd64.tar.gz
  rm go1.12.4.linux-amd64.tar.gz
}

function ensure_helm() {
  reporter "Ensuring helm"
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
}

function ensure_youtube_viewer() {
  git clone https://github.com/trizen/youtube-viewer.git /home/eggshell/youtube-viewer
  cd /home/eggshell/youtube-viewer
  cpan Module::Build
  perl Build.PL
  sudo ./Build installdeps
  sudo ./Build install
  cd -
}

function ensure_vpn() {
  /bin/su -c "sh /eggshell/post-install/laptop/data/pia.run" - eggshell
}

function main() {
  ensure_dependencies
  ensure_eggshell
  check_for_internet
  ensure_apt_sources

  reporter "Updating apt cache"
  apt update -qq

  reporter "Installing apt packages from list"
  apt install -y $(awk '{ print $1 }' data/apt_packages.list)

  reporter "Installing youtube-dl"
  pip install youtube-dl

  ensure_ohmyzsh
  ensure_owned_dirs
  ensure_zsh_syntax_highlighting
  remove_old_configs
  ensure_dotfiles
  ensure_xorg_conf
  ensure_firefox
  ensure_golang
  ensure_helm
  ensure_youtube_viewer
  ensure_vpn

  reporter "Generating user RSA keys"
  mkdir /home/eggshell/.ssh
  ssh-keygen -t rsa -N "" -f /home/eggshell/.ssh/id_rsa
  ensure_owned_dirs
}

main "$@"
