#!/bin/bash

if [[ ! -e $AVARI_QBT_HOME/qbtorrent.conf ]]; then
	echo "No qbtorrent.conf found!"
	exit 1
fi

echo "[info] Starting qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash $AVARI_QBT_HOME/qbittorrent.init start &

sleep 1
qbpid=$(pgrep -o -x qbittorrent-nox)
echo "[info] qBittorrent PID: $qbpid" | ts '%Y-%m-%d %H:%M:%.S'

if [ -e /proc/$qbpid ]; then
	if [[ -e $AVARI_QBT_HOME/logs/qbittorrent.log ]]; then
		chmod 775 $AVARI_QBT_HOME/logs/qbittorrent.log
	fi
else
	echo "qBittorrent failed to start!"
fi
