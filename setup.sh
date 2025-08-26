#!/bin/bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sudo apt update && sudo apt upgrade -y

sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y htop docker-ce rsync docker-compose-plugin cifs-utils autofs

## Setup AutoFS for Nextcloud data mountpoint
sudo mkdir -p /root/storage/nextcloud
echo '/root/storage auto.cifs' | sudo tee -a /etc/auto.master
echo 'nextcloud -fstype=cifs,iocharset=utf8,rw,seal,credentials=/root/storage-cred.txt,uid=82,gid=82,file_mode=0660,dir_mode=0770 ://u487062-sub1.your-storagebox.de/u487062-sub1' | sudo tee -a /etc/auto.cifs
sudo chmod 644 /etc/auto.cifs
sudo systemctl enable autofs
sudo service autofs restart