#!/bin/bash

# Pre-defined env variables:
#   $HOST_NETWORK
#   $WG_GATWAY

# Credits:
# https://www.linuxserver.io/blog/routing-docker-host-and-container-traffic-through-wireguard

source logging

DEFAULT_GATEWAY=$(ip route show | grep default | awk '{print $3}')
UNEXPECTED_IP=$(curl -s ifconfig.co)

ip route del default
ip route add default via "$WG_GATEWAY"
ip route add "$HOST_NETWORK" via "$DEFAULT_GATEWAY"

ufw default deny incoming
ufw default allow outgoing
ufw deny out to "$HOST_NETWORK"
ufw allow in from "$HOST_NETWORK"
ufw enable

while : ; do
	actual_ip=$(curl -s ifconfig.co)
	actual_city=$(echo "$(curl -s ifconfig.co/country): $(curl -s ifconfig.co/city)")
	if [[ $actual_ip != $UNEXPECTED_IP ]]; then
		loginfo "Assigned ip: $actual_ip $actual_city"
		break
	fi
	loginfo "Unexpected: $UNEXPECTED_IP; Actual: $actual_ip"
	sleep 3m
done
