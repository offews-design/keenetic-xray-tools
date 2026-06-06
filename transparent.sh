#!/bin/sh
set -eu

ACTION="${1:-status}"
TPORT="${TPORT:-12345}"
LAN_IF="${LAN_IF:-br0}"
CHAIN="${CHAIN:-KEENETIC_XRAY}"

need_iptables() {
  if ! command -v iptables >/dev/null 2>&1; then
    echo "ERROR: iptables not found"
    exit 1
  fi
}

delete_jump() {
  while iptables -t nat -D PREROUTING -i "$LAN_IF" -p tcp -j "$CHAIN" 2>/dev/null; do
    :
  done
}

setup_chain() {
  iptables -t nat -N "$CHAIN" 2>/dev/null || true
  iptables -t nat -F "$CHAIN"

  iptables -t nat -A "$CHAIN" -d 0.0.0.0/8 -j RETURN
  iptables -t nat -A "$CHAIN" -d 10.0.0.0/8 -j RETURN
  iptables -t nat -A "$CHAIN" -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A "$CHAIN" -d 169.254.0.0/16 -j RETURN
  iptables -t nat -A "$CHAIN" -d 172.16.0.0/12 -j RETURN
  iptables -t nat -A "$CHAIN" -d 192.168.0.0/16 -j RETURN
  iptables -t nat -A "$CHAIN" -d 224.0.0.0/4 -j RETURN
  iptables -t nat -A "$CHAIN" -d 240.0.0.0/4 -j RETURN

  iptables -t nat -A "$CHAIN" -p tcp -j REDIRECT --to-ports "$TPORT"
}

enable_rules() {
  need_iptables
  setup_chain
  delete_jump
  iptables -t nat -A PREROUTING -i "$LAN_IF" -p tcp -j "$CHAIN"
  echo "Transparent TCP redirect enabled: $LAN_IF -> 127.0.0.1:$TPORT"
  echo "UDP/QUIC is not redirected by this safe profile."
}

disable_rules() {
  need_iptables
  delete_jump
  iptables -t nat -F "$CHAIN" 2>/dev/null || true
  iptables -t nat -X "$CHAIN" 2>/dev/null || true
  echo "Transparent redirect disabled"
}

status_rules() {
  need_iptables
  echo "=== PREROUTING ==="
  iptables -t nat -S PREROUTING 2>/dev/null | grep "$CHAIN" || echo "no PREROUTING jump"
  echo
  echo "=== $CHAIN ==="
  iptables -t nat -S "$CHAIN" 2>/dev/null || echo "chain not found"
}

case "$ACTION" in
  enable|on|start) enable_rules ;;
  disable|off|stop) disable_rules ;;
  status|check) status_rules ;;
  *)
    echo "Usage: sh transparent.sh {enable|disable|status}"
    echo "Optional env: LAN_IF=br0 TPORT=12345"
    exit 1
    ;;
esac
