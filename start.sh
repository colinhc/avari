#!/bin/bash

_vpnfiles=/ovpn-files
_outfile=/tmp/vpnenv
./openvpn/random-vpn.sh --ovpn=$_vpnfiles --out_envfile=$_outfile
source $_outfile
echo "Set" `env |grep VPN_`
./qbtorrent/iptables.sh
sleep infinity
