#!/bin/sh
set -eu

ACTION="${1:-status}"
TPORT="${TPORT:-12345}"
LAN_IF="${LAN_IF:-br0}"
CHAIN="${CHAIN:-KEENETIC_XRAY}"
QUIC_CHAIN="${QUIC_CHAIN:-KEENETIC_XRAY_QUIC}"

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

delete_quic_jump() {
  while iptables -D FORWARD -i "$LAN_IF" -p udp --dport 443 -j "$QUIC_CHAIN" 2>/dev/null; do
    :
  done
}

block_quic() {
  need_iptables
  iptables -N "$QUIC_CHAIN" 2>/dev/null || true
  iptables -F "$QUIC_CHAIN"
  iptables -A "$QUIC_CHAIN" -j REJECT
  delete_quic_jump
  iptables -I FORWARD -i "$LAN_IF" -p udp --dport 443 -j "$QUIC_CHAIN"
  echo "QUIC/UDP 443 blocked for $LAN_IF. Browsers/apps should fall back to TCP."
}

unblock_quic() {
  need_iptables
  delete_quic_jump
  iptables -F "$QUIC_CHAIN" 2>/dev/null || true
  iptables -X "$QUIC_CHAIN" 2>/dev/null || true
  echo "QUIC/UDP 443 block disabled"
}

status_rules() {
  need_iptables
  echo "=== PREROUTING ==="
  iptables -t nat -S PREROUTING 2>/dev/null | grep "$CHAIN" || echo "no PREROUTING jump"
  echo
  echo "=== $CHAIN ==="
  iptables -t nat -S "$CHAIN" 2>/dev/null || echo "chain not found"
  echo
  echo "=== QUIC ==="
  iptables -S FORWARD 2>/dev/null | grep "$QUIC_CHAIN" || echo "no QUIC block"
  iptables -S "$QUIC_CHAIN" 2>/dev/null || true
}

case "$ACTION" in
  enable|on|start) enable_rules ;;
  disable|off|stop) disable_rules ;;
  block-quic) block_quic ;;
  unblock-quic) unblock_quic ;;
  status|check) status_rules ;;
  *)
    echo "Usage: sh transparent.sh {enable|disable|block-quic|unblock-quic|status}"
    echo "Optional env: LAN_IF=br0 TPORT=12345"
    exit 1
    ;;
esac
