#!/bin/sh
set -eu

INIT_SCRIPT="/opt/etc/init.d/S24xray"
TRANSPARENT_INIT="/opt/etc/init.d/S25xray-transparent"
LAN_IF="${LAN_IF:-br0}"

echo "Stopping Xray"
"$INIT_SCRIPT" stop >/dev/null 2>&1 || true

echo "Stopping transparent autostart"
"$TRANSPARENT_INIT" stop >/dev/null 2>&1 || true
rm -f "$TRANSPARENT_INIT"

echo "Removing transparent chains"
while iptables -t nat -D PREROUTING -i "$LAN_IF" -p tcp -j KEENETIC_XRAY 2>/dev/null; do
  :
done
iptables -t nat -F KEENETIC_XRAY 2>/dev/null || true
iptables -t nat -X KEENETIC_XRAY 2>/dev/null || true
while iptables -D FORWARD -i "$LAN_IF" -p udp --dport 443 -j KEENETIC_XRAY_QUIC 2>/dev/null; do
  :
done
iptables -F KEENETIC_XRAY_QUIC 2>/dev/null || true
iptables -X KEENETIC_XRAY_QUIC 2>/dev/null || true

echo "Keeping files for backup:"
echo "  /opt/bin/xray"
echo "  /opt/sbin/xray"
echo "  /opt/etc/xray/config.json"
echo "  /opt/etc/init.d/S24xray"
echo "Remove them manually if needed."
