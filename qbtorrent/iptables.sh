#!/bin/bash
# Forked from binhex's OpenVPN dockers

DEBUG=false
INCOMING_PORT=49571
WEBUI_PORT=8080

source logging

# Wait until tunnel is up
function block_on_vpn() {
	while : ; do
		tunnelstat=$(netstat -ie | grep -E "tun|tap")
		if [[ ! -z "${tunnelstat}" ]]; then
			_loginfo "Found tun | tap !"
			break
		else
			_logwarn "No tun|tap found!!"
			sleep 1
		fi
	done
}

function do_fwmark() {
    	if [[ -z `lsmod | grep iptable_mangle` ]]; then return 0; fi
	_loginfo "iptable_mangle support detected, adding fwmark for tables"
	# setup route for qbittorrent webui using set-mark to route traffic for port 8080 to eth0
	_loginfo  "${WEBUI_PORT}     webui" >> /etc/iproute2/rt_tables
	ip rule add fwmark 1 table webui
	ip route add default via ${DEFAULT_GATEWAY} table webui
	# accept output from qBittorrent webui port - used for external access
	# iptables -t mangle -A OUTPUT -p tcp --dport ${WEBUI_PORT} -j MARK --set-mark 1
	# iptables -t mangle -A OUTPUT -p tcp --sport ${WEBUI_PORT} -j MARK --set-mark 1
}

function calc_docker_network() {
	# identify docker bridge interface name (probably eth0)
	local docker_interface=$(netstat -ie | grep -vE "lo|tun|tap" | sed -n '1!p' \
		| grep -P -o -m 1 '^[\w]+')
	if [[ -z $docker_interface ]]; then _logerr "No docker_interface found!"; return 1; fi

	# identify ip for docker bridge interface
	local docker_ip=$(ifconfig "${docker_interface}" \
		| grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" \
		| grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
	if [[ -z $docker_ip ]]; then _logerr "No docker_ip found!"; return 1; fi

	# identify netmask for docker bridge interface
	local docker_mask=$(ifconfig "${docker_interface}" \
		| grep -o "netmask [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" \
		| grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
	if [[ -z $docker_mask ]]; then _logerr "No docker_mask found!"; return 1; fi

	# convert netmask into cidr format
	local docker_network=$(ipcalc "${docker_ip}" "${docker_mask}" \
		| grep -P -o -m 1 "(?<=Network:)\s+[^\s]+" \
		| sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ -z $docker_network ]]; then _logerr "No docker_network found!"; return 1; fi
	echo $docker_network
}

block_on_vpn

_loginfo "WebUI port defined as ${WEBUI_PORT}"

# strip whitespace from start and end of LAN_NETWORK
export LAN_NETWORK=$(echo "${LAN_NETWORK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
_loginfo "LAN Network defined as ${LAN_NETWORK}"

# get default gateway of interfaces as looping through them
DEFAULT_GATEWAY=$(ip -4 route list 0/0 | cut -d ' ' -f 3)
_loginfo "Default gateway defined as ${DEFAULT_GATEWAY}"

_loginfo "Adding ${LAN_NETWORK} as route via docker eth0"
ip route add "${LAN_NETWORK}" via "${DEFAULT_GATEWAY}" dev eth0

echo "[info] ip route defined as follows..." | ts '%Y-%m-%d %H:%M:%.S'
echo "--------------------"
ip route
echo "--------------------"

# setup iptables marks to allow routing of defined ports via eth0
###

do_fwmark
docker_network=$(calc_docker_network)


echo "[info] ORIGINAL iptables defined as follows..." | ts '%Y-%m-%d %H:%M:%.S'
iptables -S
iptables-save > /tmp/iptables-bak.ipt
echo "--------------------"

#----------------------------------
# iptable rules
#----------------------------------

# Flush
# Do not flush nat: iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

# set policy to drop ipv4 for input
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# set policy to drop ipv6 for input
# ip6tables -P INPUT DROP 1>&- 2>&-
# ip6tables -P OUTPUT DROP 1>&- 2>&-

# allow DNS UDP traffic
iptables -A INPUT -s 127.0.0.0/24 -d 127.0.0.0/24 -p udp -j ACCEPT
iptables -A OUTPUT -s 127.0.0.0/24 -d 127.0.0.0/24 -p udp -j ACCEPT
iptables -A INPUT -i eth0 -d "${docker_network}" -p udp -j ACCEPT
iptables -A OUTPUT -o eth0 -s "${docker_network}" -p udp -j ACCEPT
# iptables -A INPUT -i "${VPN_DEVICE_TYPE}"+ -p udp --sport 53 -j ACCEPT
# iptables -A OUTPUT -o "${VPN_DEVICE_TYPE}"+ -p udp --dport 53 -j ACCEPT

# allow HTTP cURL outbound traffic
iptables -A INPUT -i "${VPN_SERVICE_TYPE}"+ -p tcp --sport 80 -j ACCEPT
iptables -A OUTPUT -o "${VPN_DEVICE_TYPE}"+ -p tcp --dport 80 -j ACCEPT

# accept input to tunnel adapter tun
iptables -A INPUT -i "${VPN_DEVICE_TYPE}"+ -j ACCEPT
iptables -A FORWARD -i "${VPN_DEVICE_TYPE}"+ -j ACCEPT
iptables -A FORWARD -o "${VPN_DEVICE_TYPE}"+ -j ACCEPT
iptables -t nat -A POSTROUTING -o "${VPN_DEVICE_TYPE}"0 -j MASQUERADE
iptables -A OUTPUT -o "${VPN_DEVICE_TYPE}"+ -j ACCEPT

# accept input to/from LANs (172.x range is internal dhcp)
iptables -A INPUT -s "${docker_network}" -d "${docker_network}" -j ACCEPT
iptables -A OUTPUT -s "${docker_network}" -d "${docker_network}" -j ACCEPT

# accept input to vpn gateway
iptables -A INPUT -i eth0 -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT
iptables -A OUTPUT -o eth0 -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT

# accept input to qbittorrent daemon port - used for lan access
iptables -A INPUT -i eth0 -s "${LAN_NETWORK}" -p ${VPN_PROTOCOL} --dport ${INCOMING_PORT} -j ACCEPT
iptables -A OUTPUT -o eth0 -d "${LAN_NETWORK}" -p ${VPN_PROTOCOL} --sport ${INCOMING_PORT} -j ACCEPT 

# accept input to qbittorrent webui port
iptables -A INPUT -i eth0 -p tcp --dport ${WEBUI_PORT} -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport ${WEBUI_PORT} -j ACCEPT
# iptables -A INPUT -i eth0 -p tcp --sport ${WEBUI_PORT} -j ACCEPT
# iptables -A OUTPUT -o eth0 -p tcp --dport ${WEBUI_PORT} -j ACCEPT

# accept input icmp (ping)
# iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
# iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# These have to be at the end.
iptables -A OUTPUT -j DROP
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

echo "[info] NOW iptables defined as follows..." | ts '%Y-%m-%d %H:%M:%.S'
iptables -S
echo "--------------------"

exec /bin/bash /avari/qbtorrent/start.sh
