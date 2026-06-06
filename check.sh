#!/bin/sh
set -eu

XRAY_BIN="/opt/bin/xray"
XRAY_CONFIG="/opt/etc/xray/config.json"
INIT_SCRIPT="/opt/etc/init.d/S24xray"

echo "=== System ==="
uname -a || true
cat /etc/ndm/version 2>/dev/null || true

echo
echo "=== Entware ==="
command -v opkg >/dev/null 2>&1 && opkg --version || echo "opkg not found"

echo
echo "=== Xray ==="
if [ -x "$XRAY_BIN" ]; then
  "$XRAY_BIN" version | head -n 4 || true
  "$XRAY_BIN" run -test -config "$XRAY_CONFIG" || true
else
  echo "xray not found at $XRAY_BIN"
fi

echo
echo "=== Service ==="
ps | grep '[x]ray' || echo "xray process not found"

echo
echo "=== Listening ==="
netstat -lntup 2>/dev/null | grep -E '10808|12345|xray' || true

echo
echo "=== Config endpoint ==="
python3 - <<'PY' 2>/dev/null || true
import json
p="/opt/etc/xray/config.json"
data=json.load(open(p))
for o in data.get("outbounds", []):
    if o.get("tag") == "proxy":
        v=(o.get("settings",{}).get("vnext") or [{}])[0]
        st=o.get("streamSettings",{})
        print("proxy:", v.get("address"), v.get("port"), st.get("network"), st.get("security"))
PY

echo
echo "=== Connectivity ==="
if command -v curl >/dev/null 2>&1; then
  timeout 15 curl -sS --socks5-hostname 127.0.0.1:10808 https://ifconfig.me/ip || true
  echo
else
  echo "curl not found"
fi

echo
echo "=== CPU/Mem ==="
top -bn1 2>/dev/null | head -n 20 || true

