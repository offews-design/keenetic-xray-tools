#!/bin/sh
set -eu

XRAY_BIN="/opt/bin/xray"
XRAY_CONFIG="/opt/etc/xray/config.json"
INIT_SCRIPT="/opt/etc/init.d/S24xray"

find_xray_bin() {
  if [ -x "$XRAY_BIN" ]; then
    echo "$XRAY_BIN"
    return 0
  fi
  if command -v xray >/dev/null 2>&1; then
    command -v xray
    return 0
  fi
  for p in /opt/sbin/xray /opt/usr/bin/xray /opt/usr/sbin/xray /usr/bin/xray /usr/sbin/xray; do
    if [ -x "$p" ]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

curl_socks_test() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 15 curl -sS --socks5-hostname 127.0.0.1:10808 https://ifconfig.me/ip
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 15 curl -sS --socks5-hostname 127.0.0.1:10808 https://ifconfig.me/ip
  else
    curl -m 15 -sS --socks5-hostname 127.0.0.1:10808 https://ifconfig.me/ip
  fi
}

echo "=== System ==="
uname -a || true
cat /etc/ndm/version 2>/dev/null || true

echo
echo "=== Entware ==="
command -v opkg >/dev/null 2>&1 && opkg --version || echo "opkg not found"

echo
echo "=== Xray ==="
REAL_XRAY_BIN="$(find_xray_bin 2>/dev/null || true)"
if [ -n "$REAL_XRAY_BIN" ]; then
  echo "binary: $REAL_XRAY_BIN"
  "$REAL_XRAY_BIN" version | head -n 4 || true
  if [ -s "$XRAY_CONFIG" ]; then
    "$REAL_XRAY_BIN" run -test -config "$XRAY_CONFIG" || true
  else
    echo "config not found at $XRAY_CONFIG"
  fi
else
  echo "xray binary not found"
fi

echo
echo "=== Service ==="
ps | grep '[x]ray' || echo "xray process not found"
for pid in $(ps | awk '/[x]ray/ {print $1}'); do
  if [ -r "/proc/$pid/cmdline" ]; then
    echo "cmdline[$pid]: $(tr '\0' ' ' < "/proc/$pid/cmdline")"
  fi
  if [ -e "/proc/$pid/exe" ]; then
    echo "exe[$pid]: $(readlink "/proc/$pid/exe" 2>/dev/null || true)"
  fi
done

echo
echo "=== Listening ==="
netstat -lntup 2>/dev/null | grep -E '10808|12345|61219|xray' || true

echo
echo "=== Config endpoint ==="
PY_BIN=""
if command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PY_BIN="python"
fi
if command -v jq >/dev/null 2>&1 && [ -s "$XRAY_CONFIG" ]; then
  echo "config: $XRAY_CONFIG"
  jq -r '
    (.inbounds[]? | "inbound: \(.tag) \(.protocol) \(.listen):\(.port)"),
    (.outbounds[]? | select(.tag == "proxy") |
      .settings.vnext[0] as $v |
      .streamSettings as $s |
      "proxy: \($v.address) \($v.port) \($s.network) \($s.security)")
  ' "$XRAY_CONFIG" 2>/dev/null || true
elif [ -n "$PY_BIN" ]; then
  "$PY_BIN" - <<'PY' 2>/dev/null || true
import json
p="/opt/etc/xray/config.json"
data=json.load(open(p))
print("config:", p)
for i in data.get("inbounds", []):
    print("inbound:", i.get("tag"), i.get("protocol"), i.get("listen"), i.get("port"))
for o in data.get("outbounds", []):
    if o.get("tag") == "proxy":
        v=(o.get("settings",{}).get("vnext") or [{}])[0]
        st=o.get("streamSettings",{})
        print("proxy:", v.get("address"), v.get("port"), st.get("network"), st.get("security"))
PY
else
  echo "jq/python not found"
fi

echo
echo "=== Connectivity ==="
if command -v curl >/dev/null 2>&1; then
  curl_socks_test || true
  echo
else
  echo "curl not found"
fi

echo
echo "=== CPU/Mem ==="
top -bn1 2>/dev/null | head -n 20 || true
