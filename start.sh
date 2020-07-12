#!/bin/bash

alias myloc='curl -s ifconfig.co/country'
alias myip='curl -s ifconfig.co'

_outfile=/tmp/vpnenv
./openvpn/random-vpn.sh --ovpn=/ovpn-files --out_envfile=$_outfile
source $_outfile
echo "Set" $(env |grep VPN_)
./qbtorrent/iptables.sh
sleep infinity
