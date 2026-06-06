#!/bin/sh
set -eu

INIT_SCRIPT="/opt/etc/init.d/S25xray-transparent"
LAN_IF="${LAN_IF:-br0}"
TPORT="${TPORT:-12345}"
CHAIN="KEENETIC_XRAY"
QUIC_CHAIN="KEENETIC_XRAY_QUIC"

if [ ! -d /opt/etc/init.d ]; then
  echo "ERROR: /opt/etc/init.d not found. Entware is not ready."
  exit 1
fi

cat > "$INIT_SCRIPT" <<EOF
#!/bin/sh

LAN_IF="${LAN_IF}"
TPORT="${TPORT}"
CHAIN="${CHAIN}"
QUIC_CHAIN="${QUIC_CHAIN}"

delete_redirect_jump() {
  while iptables -t nat -D PREROUTING -i "\$LAN_IF" -p tcp -j "\$CHAIN" 2>/dev/null; do
    :
  done
}

delete_quic_jump() {
  while iptables -D FORWARD -i "\$LAN_IF" -p udp --dport 443 -j "\$QUIC_CHAIN" 2>/dev/null; do
    :
  done
}

start() {
  command -v iptables >/dev/null 2>&1 || exit 0

  iptables -t nat -N "\$CHAIN" 2>/dev/null || true
  iptables -t nat -F "\$CHAIN"
  iptables -t nat -A "\$CHAIN" -d 0.0.0.0/8 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 10.0.0.0/8 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 169.254.0.0/16 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 172.16.0.0/12 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 192.168.0.0/16 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 224.0.0.0/4 -j RETURN
  iptables -t nat -A "\$CHAIN" -d 240.0.0.0/4 -j RETURN
  iptables -t nat -A "\$CHAIN" -p tcp -j REDIRECT --to-ports "\$TPORT"

  delete_redirect_jump
  iptables -t nat -A PREROUTING -i "\$LAN_IF" -p tcp -j "\$CHAIN"

  iptables -N "\$QUIC_CHAIN" 2>/dev/null || true
  iptables -F "\$QUIC_CHAIN"
  iptables -A "\$QUIC_CHAIN" -j REJECT
  delete_quic_jump
  iptables -I FORWARD -i "\$LAN_IF" -p udp --dport 443 -j "\$QUIC_CHAIN"
}

stop() {
  command -v iptables >/dev/null 2>&1 || exit 0
  delete_redirect_jump
  iptables -t nat -F "\$CHAIN" 2>/dev/null || true
  iptables -t nat -X "\$CHAIN" 2>/dev/null || true
  delete_quic_jump
  iptables -F "\$QUIC_CHAIN" 2>/dev/null || true
  iptables -X "\$QUIC_CHAIN" 2>/dev/null || true
}

case "\${1:-start}" in
  start) start ;;
  stop) stop ;;
  restart) stop; start ;;
  *) echo "Usage: \$0 {start|stop|restart}"; exit 1 ;;
esac
EOF

chmod +x "$INIT_SCRIPT"

"$INIT_SCRIPT" restart

echo "Installed transparent autostart: $INIT_SCRIPT"
echo "LAN_IF=$LAN_IF TPORT=$TPORT"
