#!/bin/bash
sudo curl -SL https://raw.githubusercontent.com/junedkhatri31/docker-volume-snapshot/main/docker-volume-snapshot -o /usr/local/bin/docker-volume-snapshot
sudo chmod +x /usr/local/bin/docker-volume-snapshot

sudo docker-volume-snapshot create nextcloud_db nextcloud_db.tar.gz
sudo docker-volume-snapshot create nextcloud_nextcloud nextcloud_nextcloud.tar.gz

sudo docker-volume-snapshot restore nextcloud_db.tar.gz nextcloud_db
sudo docker-volume-snapshot restore nextcloud_nextcloud.tar.gz nextcloud_nextcloud