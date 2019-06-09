#!/bin/bash

docker run --privileged  -d \
        -v /home/samba/backup/ovpn-files:/ovpn-files \
	-v /tmp:/media \
       	-v /tmp:/torrents \
	-e "LAN_NETWORK=192.168.193.65" \
	-e "PUID=1000" \
        -e "PGID=1000" \
        -p 8080:8080 \
        -p 49571:49571 \
        -p 49571:49571/udp \
	--name qbtorrent \
	--dns 208.67.222.222 \
        9bkerzya/avari:local
