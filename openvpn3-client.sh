#!/bin/bash
#######################################################################
# Script Name: openvpn3-client.sh
# Description: script para conexão VPN openvpn cloud usando openvpn3
# Author: https://github.com/jeanrafaellourenco
# Date: 14/06/2021
# Dependencies: apt-transport-https, openvpn3
# Encode: UTF8
# Ref: https://openvpn.net/cloud-docs/openvpn-3-client-for-linux/
#######################################################################

_help() {
	cat <<EOF
Use: ${0##*/} [opção]
Opções:
     --instalar		- Se esse for o primeiro uso desse script
     --conectar   	- Para se conectar a VPN
     --status		- Verifica se está conectado a VPN
     --desconectar - Para se desconectar da VPN
[*]  Não execute com 'sudo' ou como 'root'.
[**] Use este script apenas em sistemas APT-based.
EOF
	exit 0
}

[[ $(id -u) -eq 0 ]] && _help | tail -n 2 | sed -n 1p && exit 1
[[ -z "$1" ]] && _help
[[ ! $(which apt) ]] && _help | tail -n 1 && exit 1

function instalar() {
	[[ ! $(find ~/*.ovpn 2>/dev/null) ]] && echo -e "Nenhum arquivo .ovpn encontrado em: $HOME" && exit 1 # verifica se existe um arquivo .ovpn da home do usuário.
	[[ $(which openvpn3) ]] && echo -e "Programa 'openvpn3' já está instalado!\n" && _help

	DISTRO=$(/usr/bin/lsb_release -c | awk '{ print $2 }') # Release name
	sudo apt update && sudo apt install apt-transport-https -y
	wget https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub
	sudo apt-key add openvpn-repo-pkg-key.pub
	sudo wget -O /etc/apt/sources.list.d/openvpn3.list https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-$DISTRO.list
	sudo apt update
	sudo apt install openvpn3 -y
	# importa um arquivo .ovpn da home do usuário.
	[[ ! $(find ~/*.ovpn 2>/dev/null) ]] && echo -e "Nenhum arquivo .ovpn encontrado em: $HOME" && exit 1 || openvpn3 config-import --persistent --config ~/*.ovpn

}

function status() {
	openvpn3 sessions-list
}

function conectar() {
	
	# setar dominio de interfaces de rede no momento de conectar (corrigindo erros de conexão com o openvpn cloud)
	
	# Todas as interfaces
	ip -br link | awk '{print $1}' | grep -E -i "(^wl*|^en*|^et*)" | while read line; do  sudo systemd-resolve --interface $line --set-domain ""; done
	
	# Verificando os dominios
	# resolvectl domain
	
	echo -e "\nAguarde a conexão no navegador!"
	[[ $(pidof openvpn3-service-client) ]] && echo -e "Já existe uma conexão aberta, teste se desconectar primeiro.\n" && _help
	openvpn3 session-start -p $(openvpn3 configs-list | grep "/net/openvpn/v3/configuration/")
}

function desconectar() {
	[[ ! $(pidof openvpn3-service-client) ]] && echo -e "Nenhuma conexão foi encontrada!" && exit 1
	sudo pkill -9 openvpn3*
	echo -e "Aguarde..."
	sleep 5
	echo -e "\nDesconectado!"
	status
}

while [[ "$1" ]]; do
	case "$1" in
	--instalar) instalar ;;
	--conectar) conectar ;;
	--status) status ;;
	--desconectar) desconectar ;;
	*) echo -e "Opção inválida\n" && _help ;;
	esac
	shift
done
