#!/bin/sh
set -eu

XRAY_BIN="/opt/bin/xray"
XRAY_DIR="/opt/etc/xray"
XRAY_CONFIG="$XRAY_DIR/config.json"
INIT_SCRIPT="/opt/etc/init.d/S24xray"
SOCKS_PORT="10808"

say() {
  echo "[$(date '+%H:%M:%S' 2>/dev/null || echo repair)] $*"
}

curl_socks_test() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 20 curl -sS --socks5-hostname "127.0.0.1:$SOCKS_PORT" https://ifconfig.me/ip
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 20 curl -sS --socks5-hostname "127.0.0.1:$SOCKS_PORT" https://ifconfig.me/ip
  else
    curl -m 20 -sS --socks5-hostname "127.0.0.1:$SOCKS_PORT" https://ifconfig.me/ip
  fi
}

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

fail=0

say "Checking /opt"
if [ ! -d /opt ]; then
  echo "ERROR: /opt not found. Entware/OPKG is not mounted."
  exit 1
fi

mkdir -p "$XRAY_DIR"

say "Checking required tools"
if command -v opkg >/dev/null 2>&1; then
  opkg update >/dev/null 2>&1 || true
  opkg install ca-bundle curl jq unzip coreutils-timeout >/dev/null 2>&1 || true
fi

install_xray() {
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64) XRAY_ARCH="arm64-v8a" ;;
    armv7l|armv7*) XRAY_ARCH="arm32-v7a" ;;
    mipsel*) XRAY_ARCH="mips32le" ;;
    mips*) XRAY_ARCH="mips32le" ;;
    *) echo "ERROR: unsupported arch: $ARCH"; return 1 ;;
  esac

  TMP="/opt/tmp/xray-repair"
  mkdir -p "$TMP"
  ZIP="$TMP/xray.zip"
  URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip"
  say "Downloading Xray: $URL"
  curl -L --fail -o "$ZIP" "$URL"
  unzip -o "$ZIP" -d "$TMP" >/dev/null
  if [ -x "$TMP/xray_softfloat" ]; then
    cp "$TMP/xray_softfloat" "$XRAY_BIN"
  else
    cp "$TMP/xray" "$XRAY_BIN"
  fi
  chmod 755 "$XRAY_BIN"
}

say "Checking Xray binary"
FOUND_XRAY_BIN="$(find_xray_bin 2>/dev/null || true)"
if [ -n "$FOUND_XRAY_BIN" ]; then
  XRAY_BIN="$FOUND_XRAY_BIN"
  say "Using Xray: $XRAY_BIN"
else
  say "Xray missing, installing"
  install_xray || fail=1
fi

if [ -x "$XRAY_BIN" ]; then
  "$XRAY_BIN" version | head -n 2 || true
else
  echo "ERROR: Xray binary is still missing"
  fail=1
fi

say "Checking config"
if [ ! -s "$XRAY_CONFIG" ]; then
  echo "ERROR: config not found: $XRAY_CONFIG"
  echo "Run install.sh with a VLESS link."
  fail=1
else
  if ! "$XRAY_BIN" run -test -config "$XRAY_CONFIG"; then
    echo "ERROR: invalid Xray config"
    fail=1
  fi
fi

say "Checking init script"
if [ ! -s "$INIT_SCRIPT" ]; then
  say "Init script missing, recreating"
  cat > "$INIT_SCRIPT" <<EOF
#!/bin/sh

ENABLED=yes
PROCS=xray
ARGS="run -config $XRAY_CONFIG"
PREARGS=""
DESC="Xray"
PATH=/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin:/usr/sbin:/usr/bin:/sbin:/bin

. /opt/etc/init.d/rc.func
EOF
fi
chmod +x "$INIT_SCRIPT" 2>/dev/null || true

say "Restarting Xray"
"$INIT_SCRIPT" stop >/dev/null 2>&1 || true
if ! "$INIT_SCRIPT" start; then
  echo "ERROR: failed to start Xray through init script"
  fail=1
fi

sleep 2

say "Checking process"
if ps | grep '[x]ray' >/dev/null 2>&1; then
  ps | grep '[x]ray' || true
else
  echo "ERROR: xray process not found"
  fail=1
fi

say "Checking listening ports"
netstat -lntup 2>/dev/null | grep -E "$SOCKS_PORT|12345|xray" || true

say "Testing SOCKS proxy"
if command -v curl >/dev/null 2>&1; then
  if curl_socks_test; then
    echo
    say "SOCKS test OK"
  else
    echo
    echo "WARN: SOCKS test failed"
    fail=1
  fi
else
  echo "WARN: curl not found, skipping SOCKS test"
fi

say "CPU/Mem snapshot"
top -bn1 2>/dev/null | head -n 12 || true

if [ "$fail" = "0" ]; then
  say "Repair finished: OK"
else
  say "Repair finished with warnings/errors"
fi

exit "$fail"
