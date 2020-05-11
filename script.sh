#!/bin/bash
echo "######################################################"
echo "# This script setup Wireguard for you, and creates a #"
echo "# simple cli tool.                                   #"
echo "#                                                    #"
echo "#            Created By Lukas Bonrath                #"
echo "######################################################"

#Check for root rights
if [ "$EUID" -ne 0 ]
then 
			echo "Please run as root or with sudo"
			    exit
fi

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

#Set IP and netmask
ip_client=$interface_ip
ip_client+=/

#Set netmask
read -p "Enter the netmask, default is 32" ip_client_mask

#Check for empty variable
if [[ -z "$ip_client_mask" ]]; then
			ip_client_mask=32
fi

ip_client+=$ip_client_mask

#Create private and public key
cd /etc/wireguard/
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

#Pivate Key
pri_key=$(cat privatekey)

#Public Key
pub_key=$(cat publickey)

#Create wg0.conf config file
cat <<EOF>>wg0.conf
[interface]
Address = $interface_ip
PrivateKey = $pri_key
ListenPort = $port

[Peer]
PublicKey = $pub_key
AllowedIPs = $ip_client
EOF

