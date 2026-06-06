#!/bin/sh
set -eu

INIT_SCRIPT="/opt/etc/init.d/S24xray"

echo "Stopping Xray"
"$INIT_SCRIPT" stop >/dev/null 2>&1 || true

echo "Removing transparent chain"
iptables -t nat -D PREROUTING -p tcp -j KEENETIC_XRAY 2>/dev/null || true
iptables -t nat -F KEENETIC_XRAY 2>/dev/null || true
iptables -t nat -X KEENETIC_XRAY 2>/dev/null || true

echo "Keeping files for backup:"
echo "  /opt/bin/xray"
echo "  /opt/etc/xray/config.json"
echo "  /opt/etc/init.d/S24xray"
echo "Remove them manually if needed."

