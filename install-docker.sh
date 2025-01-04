#!/usr/bin bash

# docker run -it --name=steamcmd cm2network/steamcmd bash

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done

apt-get update
apt-get -y install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

VERSION_STRING=5:27.4.0-1~ubuntu.24.04~noble
apt-get -y install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

mkdir /opt/valheim-data
chmod 777 /opt/valheim-data

docker run -d --net=host -v "/opt/valheim-data:/home/steam/valheim-dedicated/" -e SERVER_PORT=2456 --name=valheim-dedicated cm2network/valheim
