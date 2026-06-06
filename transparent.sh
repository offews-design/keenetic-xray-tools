#!/bin/sh
set -eu

TPORT="${TPORT:-12345}"
LAN_IF="${LAN_IF:-br0}"

echo "Enabling basic transparent TCP redirect for selected destinations is platform-specific."
echo "This script creates an empty KEENETIC_XRAY chain and does not redirect all traffic by default."
echo "Use it as a safe scaffold, then add ipset-based rules after validating on a real router."

iptables -t nat -N KEENETIC_XRAY 2>/dev/null || true
iptables -t nat -F KEENETIC_XRAY

iptables -t nat -A KEENETIC_XRAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 10.0.0.0/8 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 169.254.0.0/16 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 172.16.0.0/12 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 192.168.0.0/16 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 224.0.0.0/4 -j RETURN
iptables -t nat -A KEENETIC_XRAY -d 240.0.0.0/4 -j RETURN

echo "Transparent scaffold installed. No PREROUTING redirect added automatically."
echo "For mass deployment, adapt this after confirming Keenetic firmware firewall layout."

