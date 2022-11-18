#!/bin/bash
#######################################################################
# Script Name: openvpn3-client.sh
# Description: script for openvpn cloud VPN connection using openvpn3
# Author: https://github.com/jeanrafaellourenco
# Date: 14/06/2021
# Dependencies: apt-transport-https, openvpn3
# Encode: UTF8
# Ref: https://openvpn.net/cloud-docs/openvpn-3-client-for-linux/
#######################################################################

_help() {
	cat <<EOF
Use: ${0##*/} [option]
Options:
    --install		- If this is the first use of this script
    --connect   	- To connect to VPN
    --status		- Check if you are connected to VPN
    --statistics	- Getting tunnel statistics For already running tunnels
    --disconnect 	- To disconnect from the VPN
[*]  Do not run with 'sudo' or as 'root'.
[**] Use this script only on APT-based systems.
EOF
	exit 0
}

[[ $(id -u) -eq 0 ]] && _help | tail -n 2 | sed -n 1p && exit 1
[[ -z "$1" ]] && _help
[[ ! $(which apt) ]] && _help | tail -n 1 && exit 1

function install() {
	[[ ! $(find ~/*.ovpn 2>/dev/null) ]] && echo -e "No *.ovpn files found in: $HOME" && exit 1 # check if there is an .ovpn file of the user's home.
	[[ $(which openvpn3) ]] && echo -e "Program 'openvpn3' is already installed!\n" && _help

	DISTRO=$(/usr/bin/lsb_release -c | awk '{ print $2 }') # Release name
	[[ $DISTRO == "una" ]] && DISTRO="focal" || [[ $DISTRO == "vanessa" ]] && DISTRO="jammy"
	sudo apt update && sudo apt install apt-transport-https -y
	wget https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub
	sudo apt-key add openvpn-repo-pkg-key.pub
	sudo wget -O /etc/apt/sources.list.d/openvpn3.list https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-$DISTRO.list
	sudo apt update
	sudo apt install openvpn3 -y
	# imports a .ovpn file from the user's home.
	[[ ! $(find ~/*.ovpn 2>/dev/null) ]] && echo -e "No *.ovpn files found in: $HOME" && exit 1 || openvpn3 config-import --persistent --config ~/*.ovpn

}

function status() {
	openvpn3 sessions-list
}

function connect() {
	SESSION=$(openvpn3 sessions-list | grep "/net/openvpn/v3/sessions/" | awk '{ print $2 }')
	[[ -n $SESSION ]] && echo -e "There is already an open connection, try disconnecting first.\n" && _help
	echo -e "Wait for connection..."
	openvpn3 session-start -p $(openvpn3 configs-list | grep "/net/openvpn/v3/configuration/")
}

function statistics() {
	SESSION=$(openvpn3 sessions-list | grep "/net/openvpn/v3/sessions/" | awk '{ print $2 }')
	[[ -z $SESSION ]] && echo -e "No sessions available.\n" && _help
	openvpn3 session-stats --path $SESSION
}

function disconnect() {
	SESSION=$(openvpn3 sessions-list | grep "/net/openvpn/v3/sessions/" | awk '{ print $2 }')
	[[ -z $SESSION ]] && echo -e "No sessions available.\n" && _help
	echo -e "wait to disconnect..."
	openvpn3 session-manage --path $SESSION --disconnect
	sleep 5
	echo -e "\nDisconnected!"
	status
}

while [[ "$1" ]]; do
	case "$1" in
	--install) install ;;
	--connect) connect ;;
	--status) status ;;
	--statistics) statistics ;;
	--disconnect) disconnect ;;
	*) echo -e "Invalid option\n" && _help ;;
	esac
	shift
done
