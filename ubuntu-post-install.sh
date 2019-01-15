#!/bin/bash

set -eux

sudo add-apt-repository -y universe
sudo add-apt-repository -y ppa:linrunner/tlp
sudo apt update
#sudo apt update && sudo apt upgrade -y
sudo apt install -y $(awk '{ print $1 }' data/apt_packages.list)

# Install discord
TEMP_DEB="$(mktemp)" &&
wget -O "$TEMP_DEB" 'https://discordapp.com/api/download?platform=linux&format=deb' &&
sudo dpkg -i "$TEMP_DEB"
rm -f "$TEMP_DEB"

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt install -y docker-ce

# Install kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubectl

# Install ibmcloud
curl -sL https://ibm.biz/idt-installer | bash

# Install oh-my-zsh
CURRENT_USER=$(whoami)
sudo usermod -s /usr/bin/zsh $CURRENT_USER
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | grep -Ev 'chsh -s|env zsh')"
