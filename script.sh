#!/bin/bash
echo "######################################################"
echo "# This script setup Wireguard for you, and creates a #"
echo "# simple cli tool.                                   #"
echo "#                                                    #"
echo "#            Created By Lukas Bonrath                #"
echo "######################################################"

#Check for root rights
if [[ "$EUID" -ne 0 ]]; then 
	echo "Please run as root or with sudo"
	exit
fi

if [[ "$1" == "install" ]]; then
	#Git repo
	git_repo=https://github.com/lucki1000/wireguard-installer.git

	#Set wireguard port
	read -p "Enter the port you wish to run wireguard on it, default is 51820: " port

	#Set default interface IP
	read -p "Set Interface IP, default is 10.1.1.1: " interface_ip

	#Check if variable empty
	if [[ -z "$port" ]]; then
		port=51820
	fi

	if [[ -z "$interface_ip" ]]; then
		interface_ip=10.1.1.1
	fi

	#Set DNS Server
	    read -p "Enter DNS, leave empty when you would use default value: " dns

    #Check for empty value
	if [[ -z "dns" ]]; then
		dns=$interface_ip
	fi

	#Set IP and netmask
	ip_client=$interface_ip
	ip_client+=/

	#Set netmask
	read -p "Enter the netmask, default is 32: " ip_client_mask

	#Check for empty value
	if [[ -z "$ip_client_mask" ]]; then
		ip_client_mask=32
	fi

	ip_client+=$ip_client_mask

	#Create private and public key
	cd /etc/wireguard/
	umask 077
	wg genkey | tee server_private.key | wg pubkey > server_public.key
	wg genkey | tee client_private.key | wg pubkey > client_public.key
	#Pivate Key (Server)
	ser_pri_key=$(cat server_private.key)
	ser_pub_key=$(cat server_public.key)

	#Public Key (client)
	cli_pri_key=$(cat client_private.key)
	cli_pub_key=$(cat client_public.key)

	#Create wg0.conf config file
	cat <<EOF>wg0.conf
	[interface]
	Address = $interface_ip
	PrivateKey = $ser_pri_key
	ListenPort = $port
	PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
	SaveConfig = true
	[Peer]
	PublicKey = $cli_pub_key
	AllowedIPs = $ip_client
	EOF
	sudo systemctl enable wg-quick@wg0
	wg-quick up wg0
	mkdir /etc/wireguard-installer
	echo "port="$port "\ninterface_ip="$interface_ip "\nser_pri_key="$ser_pri_key "\nser_pub_key="$ser_pub_key "\ncli_pri_key="$cli_pri_key "\ncli_pub_key="$cli_pub_key >> /etc/wireguard-installer/vars.conf
	read -p "Your Public IP or DynDns: " pub_ip_or_domain
	echo "pub_ip_or_domain="$pub_ip_or_domain >> /etc/wireguard-installer/vars.conf
	echo "ip_client_mask="$ip_client_mask >> /etc/wireguard-installer/vars.conf
	echo "dns="$dns >> /etc/wireguard-installer/vars.conf
	mkdir ~/client_configs/
fi

source /etc/wireguard-installer/vars.conf
if [[ "$1" == "start" ]]; then
	sudo wg-quick up wg0
fi

if [[ "$1" == "stop" ]]; then
	sudo wg-quick down wg0
fi

if [[ "$1" == "status" ]]; then
	sudo wg show
fi

if [[ "$1" == "add" ]]; then
	read -p "Name of client: " cli_name
	read -p "Type the IP for your device: " device_ip
	
	cat <<EOF>>~/client_configs/{cli_name}.conf
	[Interface]
	Address = $device_ip/$ip_client_mask
	PrivateKey = $cli_pri_key
	DNS = $dns

	[Peer]
	PublicKey = $ser_pub_key
	Endpoint = $pub_ip_or_domain:$port
	AllowedIPs = 0.0.0.0/0
	PersistentKeepalive = 21
	EOF
fi
