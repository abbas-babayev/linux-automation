#!/bin/bash
set -e
if [ "$EUID" -ne 0 ]; then echo "Run as root"; exit 1; fi
apt update && apt install wireguard -y
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
cd /etc/wireguard
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key
cat > wg0.conf << EOF2
[Interface]
PrivateKey = $(cat server_private.key)
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF2
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
echo "Done! Public key: $(cat server_public.key)"
