#!/bin/bash
chown -R ${PUID}:${PGID} $AVARI_QBT_HOME/config

if [[ ! -e $AVARI_QBT_HOME/qbtorrent.conf ]]; then
	echo "No qbtorrent.conf found!"
	exit 1
fi

# set umask
export UMASK=$(echo "${UMASK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

if [[ ! -z "${UMASK}" ]]; then
  echo "[info] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
else
  echo "[warn] UMASK not defined (via -e UMASK), defaulting to '002'" | ts '%Y-%m-%d %H:%M:%.S'
  export UMASK="002"
fi

# Set qBittorrent WebUI and Incoming ports
if [ ! -z "${WEBUI_PORT}" ]; then
	webui_port_exist=$(cat $AVARI_QBT_HOME/qbtorrent.conf | grep -m 1 'WebUI\\Port='${WEBUI_PORT})
	if [[ -z "${webui_port_exist}" ]]; then
		webui_exist=$(cat $AVARI_QBT_HOME/qbtorrent.conf | grep -m 1 'WebUI\\Port')
		if [[ ! -z "${webui_exist}" ]]; then
			# Get line number of WebUI Port
			LINE_NUM=$(grep -Fn -m 1 'WebUI\Port' $AVARI_QBT_HOME/qbtorrent.conf | cut -d: -f 1)
			sed -i "${LINE_NUM}s@.*@WebUI\\Port=${WEBUI_PORT}@" $AVARI_QBT_HOME/qbtorrent.conf
		else
			echo "WebUI\Port=${WEBUI_PORT}" >> $AVARI_QBT_HOME/qbtorrent.conf
		fi
	fi
fi

if [ ! -z "${INCOMING_PORT}" ]; then
	incoming_port_exist=$(cat $AVARI_QBT_HOME/qbtorrent.conf | grep -m 1 'Connection\\PortRangeMin='${INCOMING_PORT})
	if [[ -z "${incoming_port_exist}" ]]; then
		incoming_exist=$(cat $AVARI_QBT_HOME/qbtorrent.conf | grep -m 1 'Connection\\PortRangeMin')
		if [[ ! -z "${incoming_exist}" ]]; then
			# Get line number of Incoming
			LINE_NUM=$(grep -Fn -m 1 'Connection\PortRangeMin' $AVARI_QBT_HOME/qbtorrent.conf | cut -d: -f 1)
			sed -i "${LINE_NUM}s@.*@Connection\\PortRangeMin=${INCOMING_PORT}@" $AVARI_QBT_HOME/qbtorrent.conf
		else
			echo "Connection\PortRangeMin=${INCOMING_PORT}" >> $AVARI_QBT_HOME/qbtorrent.conf
		fi
	fi
fi

echo "[info] Starting qBittorrent daemon..." | ts '%Y-%m-%d %H:%M:%.S'
/bin/bash $AVARI_QBT_HOME/qbittorrent.init start &
chmod -R 755 $AVARI_QBT_HOME/config

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
