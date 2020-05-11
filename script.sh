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

#Create private and public key
cd /etc/wireguard/
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

#Create wg0.conf config file
cp -r  /etc/wireguard/wg0.conf
