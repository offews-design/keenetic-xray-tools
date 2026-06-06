#!/bin/sh
set -eu

XRAY_CONFIG="/opt/etc/xray/config.json"
INIT_SCRIPT="/opt/etc/init.d/S24xray"
BACKUP_ROOT="/opt/root/xray-backups"

find_xray_bin() {
  for p in /opt/bin/xray /opt/sbin/xray /opt/usr/bin/xray /opt/usr/sbin/xray /usr/bin/xray /usr/sbin/xray; do
    if [ -x "$p" ]; then
      echo "$p"
      return 0
    fi
  done
  if command -v xray >/dev/null 2>&1; then
    command -v xray
    return 0
  fi
  return 1
}

if [ ! -s "$XRAY_CONFIG" ]; then
  echo "ERROR: config not found: $XRAY_CONFIG"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found. Run: opkg install jq"
  exit 1
fi

XRAY_BIN="$(find_xray_bin 2>/dev/null || true)"
if [ -z "$XRAY_BIN" ]; then
  echo "ERROR: xray binary not found"
  exit 1
fi

TS="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo manual)"
DEST="$BACKUP_ROOT/$TS"
mkdir -p "$DEST"
cp -a "$XRAY_CONFIG" "$DEST/config.json.before-transparent-listen"
echo "Backup: $DEST/config.json.before-transparent-listen"

TMP="$XRAY_CONFIG.tmp.$$"
jq '
  .inbounds |= map(
    if .tag == "transparent-in"
    then .listen = "0.0.0.0"
    else .
    end
  )
' "$XRAY_CONFIG" > "$TMP"
mv "$TMP" "$XRAY_CONFIG"

"$XRAY_BIN" run -test -config "$XRAY_CONFIG"

"$INIT_SCRIPT" stop >/dev/null 2>&1 || true
for pid in $(ps | awk "/[x]ray/ {print \$1}"); do
  kill "$pid" 2>/dev/null || true
done
sleep 1
"$INIT_SCRIPT" start

echo "transparent-in listen fixed to 0.0.0.0"
netstat -lntup 2>/dev/null | grep -E "10808|12345|xray" || true
