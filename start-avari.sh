#!/bin/bash

docker run --privileged -d \
	-v /home/samba/backup/ovpn-files:/ovpn-files \
	-v /usr/local/samba/content/movies:/media \
	-v /usr/local/samba/content:/torrents \
        -v /tmp:/tmp \
	-e "LAN_NETWORK=192.168.193.0/24" \
	-e "PUID=1002" \
	-e "PGID=1002" \
	-p 8080:8080 \
	-p 49571:49571 \
	-p 49571:49571/udp \
	--name qbtorrent \
	--dns 1.1.1.1 \
	9bkerzya/avari:local
