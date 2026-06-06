#!/bin/sh
set -eu

VLESS_URL="${1:-}"
TRANSPARENT="${2:-}"

XRAY_BIN="/opt/bin/xray"
XRAY_DIR="/opt/etc/xray"
XRAY_CONFIG="$XRAY_DIR/config.json"
INIT_SCRIPT="/opt/etc/init.d/S24xray"
TPROXY_PORT="12345"

if [ -z "$VLESS_URL" ]; then
  echo "Usage: sh keenetic-install.sh 'vless://...' [--transparent]"
  exit 1
fi

if [ ! -d /opt ]; then
  echo "Entware /opt not found. Install/enable Entware on Keenetic first."
  exit 1
fi

mkdir -p "$XRAY_DIR"

echo "[1/7] Checking packages"
if command -v opkg >/dev/null 2>&1; then
  opkg update || true
  opkg install ca-bundle curl jq iptables ipset coreutils-timeout >/dev/null 2>&1 || true
fi

echo "[2/7] Installing Xray if missing"
if [ ! -x "$XRAY_BIN" ]; then
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64) XRAY_ARCH="arm64-v8a" ;;
    armv7l|armv7*) XRAY_ARCH="arm32-v7a" ;;
    mipsel*) XRAY_ARCH="mips32le" ;;
    mips*) XRAY_ARCH="mips32" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac

  TMP="/opt/tmp/xray-install"
  mkdir -p "$TMP"
  ZIP="$TMP/xray.zip"
  URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip"
  echo "Downloading $URL"
  curl -L --fail -o "$ZIP" "$URL"
  unzip -o "$ZIP" -d "$TMP"
  install -m 755 "$TMP/xray" "$XRAY_BIN"
fi

echo "[3/7] Parsing VLESS URL"
python3 - "$VLESS_URL" "$XRAY_CONFIG" <<'PY'
import json, sys, urllib.parse

url = sys.argv[1]
out = sys.argv[2]

u = urllib.parse.urlsplit(url)
if u.scheme != "vless":
    raise SystemExit("Only vless:// URL is supported")

uuid = urllib.parse.unquote(u.username or "")
host = u.hostname
port = u.port
q = urllib.parse.parse_qs(u.query)
def one(key, default=""):
    return q.get(key, [default])[0]

security = one("security", "reality")
network = one("type", one("network", "tcp"))
flow = one("flow", "")
sni = one("sni", one("serverName", ""))
fp = one("fp", one("fingerprint", "chrome"))
pbk = one("pbk", one("publicKey", ""))
sid = one("sid", one("shortId", ""))
spx = one("spx", one("spiderX", "/"))
path = one("path", "/")
host_header = one("host", "")

if not all([uuid, host, port]):
    raise SystemExit("Bad VLESS URL: missing uuid/host/port")

stream = {
    "network": network,
    "security": security,
}

if network == "tcp":
    stream["tcpSettings"] = {"header": {"type": "none"}}
elif network in ("xhttp", "splithttp"):
    stream["xhttpSettings"] = {
        "path": path or "/",
        "mode": "auto",
        "extra": {
            "headers": {}
        }
    }
    if host_header:
        stream["xhttpSettings"]["host"] = host_header
elif network == "ws":
    stream["wsSettings"] = {"path": path or "/", "headers": {}}
    if host_header:
        stream["wsSettings"]["headers"]["Host"] = host_header

if security == "reality":
    stream["realitySettings"] = {
        "serverName": sni,
        "fingerprint": fp,
        "publicKey": pbk,
        "shortId": sid,
        "spiderX": spx or "/"
    }
elif security == "tls":
    stream["tlsSettings"] = {
        "serverName": sni,
        "fingerprint": fp,
        "allowInsecure": False
    }

user = {
    "id": uuid,
    "encryption": "none"
}
if flow:
    user["flow"] = flow

config = {
    "log": {"loglevel": "warning"},
    "dns": {
        "servers": [
            "1.1.1.1",
            "8.8.8.8"
        ],
        "queryStrategy": "UseIPv4"
    },
    "inbounds": [
        {
            "tag": "socks-in",
            "listen": "127.0.0.1",
            "port": 10808,
            "protocol": "socks",
            "settings": {
                "udp": True,
                "auth": "noauth"
            },
            "sniffing": {
                "enabled": True,
                "destOverride": ["http", "tls", "quic"]
            }
        },
        {
            "tag": "transparent-in",
            "listen": "127.0.0.1",
            "port": 12345,
            "protocol": "dokodemo-door",
            "settings": {
                "network": "tcp,udp",
                "followRedirect": True
            },
            "sniffing": {
                "enabled": True,
                "destOverride": ["http", "tls", "quic"]
            }
        }
    ],
    "outbounds": [
        {
            "tag": "proxy",
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": host,
                        "port": port,
                        "users": [user]
                    }
                ]
            },
            "streamSettings": stream
        },
        {"tag": "direct", "protocol": "freedom"},
        {"tag": "block", "protocol": "blackhole"}
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "direct"
            },
            {
                "type": "field",
                "domain": [
                    "domain:youtube.com",
                    "domain:www.youtube.com",
                    "domain:m.youtube.com",
                    "domain:youtu.be",
                    "domain:googlevideo.com",
                    "domain:ytimg.com",
                    "domain:ggpht.com",
                    "domain:youtubei.googleapis.com",
                    "domain:youtube.googleapis.com",
                    "domain:instagram.com",
                    "domain:www.instagram.com",
                    "domain:i.instagram.com",
                    "domain:cdninstagram.com",
                    "domain:fbcdn.net",
                    "domain:facebook.com",
                    "domain:graph.facebook.com",
                    "domain:t.me",
                    "domain:telegram.org",
                    "domain:web.telegram.org"
                ],
                "outboundTag": "proxy"
            },
            {
                "type": "field",
                "ip": [
                    "91.108.4.0/22",
                    "91.108.8.0/22",
                    "91.108.12.0/22",
                    "91.108.16.0/22",
                    "91.108.20.0/22",
                    "91.108.56.0/22",
                    "149.154.160.0/20",
                    "185.76.151.0/24"
                ],
                "outboundTag": "proxy"
            }
        ]
    }
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(config, f, ensure_ascii=False, indent=2)
    f.write("\n")
print("Wrote", out)
PY

echo "[4/7] Writing init script"
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
chmod +x "$INIT_SCRIPT"

echo "[5/7] Testing config"
"$XRAY_BIN" run -test -config "$XRAY_CONFIG"

echo "[6/7] Starting Xray"
"$INIT_SCRIPT" stop >/dev/null 2>&1 || true
"$INIT_SCRIPT" start

echo "[7/7] Optional transparent mode"
if [ "$TRANSPARENT" = "--transparent" ]; then
  sh "$(dirname "$0")/keenetic-enable-transparent.sh" || true
else
  echo "Transparent redirect is not enabled. To enable later:"
  echo "  sh keenetic-enable-transparent.sh"
fi

echo
echo "Done. SOCKS test proxy: 127.0.0.1:10808"
echo "Run: sh keenetic-check.sh"

