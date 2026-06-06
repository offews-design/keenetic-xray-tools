#!/bin/sh
set -eu

VLESS_URL="${1:-}"
TRANSPARENT="${2:-}"

XRAY_BIN="/opt/bin/xray"
XRAY_DIR="/opt/etc/xray"
XRAY_CONFIG="$XRAY_DIR/config.json"
INIT_SCRIPT="/opt/etc/init.d/S24xray"
TPROXY_PORT="12345"
BACKUP_ROOT="/opt/root/xray-backups"

if [ -z "$VLESS_URL" ]; then
  echo "Usage: sh keenetic-install.sh 'vless://...' [--transparent]"
  exit 1
fi

if [ ! -d /opt ]; then
  echo "Entware /opt not found. Install/enable Entware on Keenetic first."
  exit 1
fi

mkdir -p "$XRAY_DIR"

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

backup_existing() {
  TS="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo manual)"
  DEST="$BACKUP_ROOT/$TS"
  mkdir -p "$DEST"
  [ -e "$XRAY_CONFIG" ] && cp -a "$XRAY_CONFIG" "$DEST/config.json"
  [ -e "$INIT_SCRIPT" ] && cp -a "$INIT_SCRIPT" "$DEST/S24xray"
  [ -e "$XRAY_BIN" ] && cp -a "$XRAY_BIN" "$DEST/xray"
  ps | grep '[x]ray' > "$DEST/xray.ps" 2>/dev/null || true
  netstat -lntup > "$DEST/netstat.txt" 2>/dev/null || true
  echo "Backup directory: $DEST"
}

url_decode() {
  printf '%s' "$1" |
    sed \
      -e 's/%2[Ff]/\//g' \
      -e 's/%3[Aa]/:/g' \
      -e 's/%3[Ff]/?/g' \
      -e 's/%26/\&/g' \
      -e 's/%3[Dd]/=/g' \
      -e 's/%2[Bb]/+/g' \
      -e 's/%40/@/g' \
      -e 's/%20/ /g' \
      -e 's/%25/%/g'
}

query_value() {
  key="$1"
  default="$2"
  printf '%s\n' "$QUERY" |
    tr '&' '\n' |
    awk -F= -v k="$key" -v d="$default" '$1 == k {print substr($0, length(k) + 2); found=1; exit} END {if (!found) print d}'
}

echo "[1/7] Checking packages"
if command -v opkg >/dev/null 2>&1; then
  opkg update || true
  opkg install ca-bundle curl jq unzip iptables ipset coreutils-timeout >/dev/null 2>&1 || true
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found. Install Entware package: opkg install jq"
  exit 1
fi

echo "[1.5/7] Backing up existing Xray files"
backup_existing

echo "[2/7] Installing Xray if missing"
FOUND_XRAY_BIN="$(find_xray_bin 2>/dev/null || true)"
if [ -n "$FOUND_XRAY_BIN" ]; then
  XRAY_BIN="$FOUND_XRAY_BIN"
  echo "Using existing Xray: $XRAY_BIN"
else
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64) XRAY_ARCH="arm64-v8a" ;;
    armv7l|armv7*) XRAY_ARCH="arm32-v7a" ;;
    mipsel*) XRAY_ARCH="mips32le" ;;
    mips*) XRAY_ARCH="mips32le" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac

  TMP="/opt/tmp/xray-install"
  mkdir -p "$TMP"
  ZIP="$TMP/xray.zip"
  URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip"
  echo "Downloading $URL"
  curl -L --fail -o "$ZIP" "$URL"
  unzip -o "$ZIP" -d "$TMP"
  if [ -x "$TMP/xray_softfloat" ]; then
    cp "$TMP/xray_softfloat" "$XRAY_BIN"
  else
    cp "$TMP/xray" "$XRAY_BIN"
  fi
  chmod 755 "$XRAY_BIN"
fi

echo "[3/7] Parsing VLESS URL"
case "$VLESS_URL" in
  vless://*) ;;
  *) echo "Only vless:// URL is supported"; exit 1 ;;
esac

URL_NO_SCHEME="${VLESS_URL#vless://}"
BEFORE_QUERY="${URL_NO_SCHEME%%\?*}"
QUERY=""
[ "$BEFORE_QUERY" != "$URL_NO_SCHEME" ] && QUERY="${URL_NO_SCHEME#*\?}"
BEFORE_HASH="${BEFORE_QUERY%%#*}"

UUID="${BEFORE_HASH%@*}"
SERVER_PORT="${BEFORE_HASH#*@}"
HOST="${SERVER_PORT%:*}"
PORT="${SERVER_PORT##*:}"

SECURITY="$(url_decode "$(query_value security reality)")"
NETWORK="$(url_decode "$(query_value type "$(query_value network tcp)")")"
FLOW="$(url_decode "$(query_value flow "")")"
SNI="$(url_decode "$(query_value sni "$(query_value serverName "")")")"
FP="$(url_decode "$(query_value fp "$(query_value fingerprint chrome)")")"
PBK="$(url_decode "$(query_value pbk "$(query_value publicKey "")")")"
SID="$(url_decode "$(query_value sid "$(query_value shortId "")")")"
SPX="$(url_decode "$(query_value spx "$(query_value spiderX /)")")"
PATH_VALUE="$(url_decode "$(query_value path /)")"
HOST_HEADER="$(url_decode "$(query_value host "")")"

if [ -z "$UUID" ] || [ -z "$HOST" ] || [ -z "$PORT" ] || [ "$HOST" = "$SERVER_PORT" ]; then
  echo "Bad VLESS URL: missing uuid/host/port"
  exit 1
fi

JQ_STREAM='
  {network: $network, security: $security}
  | if $network == "tcp" then . + {tcpSettings: {header: {type: "none"}}}
    elif ($network == "xhttp" or $network == "splithttp") then . + {xhttpSettings: ({path: $path, mode: "auto", extra: {headers: {}}} + (if $host_header != "" then {host: $host_header} else {} end))}
    elif $network == "ws" then . + {wsSettings: ({path: $path, headers: {}} + (if $host_header != "" then {headers: {Host: $host_header}} else {} end))}
    else .
    end
  | if $security == "reality" then . + {realitySettings: {serverName: $sni, fingerprint: $fp, publicKey: $pbk, shortId: $sid, spiderX: $spx}}
    elif $security == "tls" then . + {tlsSettings: {serverName: $sni, fingerprint: $fp, allowInsecure: false}}
    else .
    end
'

jq -n \
  --arg uuid "$UUID" \
  --arg host "$HOST" \
  --argjson port "$PORT" \
  --arg flow "$FLOW" \
  --arg network "$NETWORK" \
  --arg security "$SECURITY" \
  --arg sni "$SNI" \
  --arg fp "$FP" \
  --arg pbk "$PBK" \
  --arg sid "$SID" \
  --arg spx "$SPX" \
  --arg path "$PATH_VALUE" \
  --arg host_header "$HOST_HEADER" \
  --argjson tproxy_port "$TPROXY_PORT" \
  "$JQ_STREAM as \$stream |
  {
    log: {loglevel: \"warning\"},
    dns: {
      servers: [\"1.1.1.1\", \"8.8.8.8\"],
      queryStrategy: \"UseIPv4\"
    },
    inbounds: [
      {
        tag: \"socks-in\",
        listen: \"127.0.0.1\",
        port: 10808,
        protocol: \"socks\",
        settings: {udp: true, auth: \"noauth\"},
        sniffing: {enabled: true, destOverride: [\"http\", \"tls\", \"quic\"]}
      },
      {
        tag: \"transparent-in\",
        listen: \"0.0.0.0\",
        port: \$tproxy_port,
        protocol: \"dokodemo-door\",
        settings: {network: \"tcp,udp\", followRedirect: true},
        sniffing: {enabled: true, destOverride: [\"http\", \"tls\", \"quic\"]}
      }
    ],
    outbounds: [
      {
        tag: \"proxy\",
        protocol: \"vless\",
        settings: {
          vnext: [
            {
              address: \$host,
              port: \$port,
              users: [({id: \$uuid, encryption: \"none\"} + (if \$flow != \"\" then {flow: \$flow} else {} end))]
            }
          ]
        },
        streamSettings: \$stream
      },
      {tag: \"direct\", protocol: \"freedom\"},
      {tag: \"block\", protocol: \"blackhole\"}
    ],
    routing: {
      domainStrategy: \"IPIfNonMatch\",
      rules: [
        {
          type: \"field\",
          ip: [
            \"0.0.0.0/8\",
            \"10.0.0.0/8\",
            \"100.64.0.0/10\",
            \"127.0.0.0/8\",
            \"169.254.0.0/16\",
            \"172.16.0.0/12\",
            \"192.168.0.0/16\",
            \"224.0.0.0/4\",
            \"240.0.0.0/4\"
          ],
          outboundTag: \"direct\"
        },
        {
          type: \"field\",
          domain: [
            \"domain:youtube.com\",
            \"domain:www.youtube.com\",
            \"domain:m.youtube.com\",
            \"domain:youtu.be\",
            \"domain:googlevideo.com\",
            \"domain:ytimg.com\",
            \"domain:ggpht.com\",
            \"domain:youtubei.googleapis.com\",
            \"domain:youtube.googleapis.com\",
            \"domain:instagram.com\",
            \"domain:www.instagram.com\",
            \"domain:i.instagram.com\",
            \"domain:cdninstagram.com\",
            \"domain:fbcdn.net\",
            \"domain:facebook.com\",
            \"domain:graph.facebook.com\",
            \"domain:t.me\",
            \"domain:telegram.org\",
            \"domain:web.telegram.org\"
          ],
          outboundTag: \"proxy\"
        },
        {
          type: \"field\",
          ip: [
            \"91.108.4.0/22\",
            \"91.108.8.0/22\",
            \"91.108.12.0/22\",
            \"91.108.16.0/22\",
            \"91.108.20.0/22\",
            \"91.108.56.0/22\",
            \"149.154.160.0/20\",
            \"185.76.151.0/24\"
          ],
          outboundTag: \"proxy\"
        }
      ]
    }
  }" > "$XRAY_CONFIG"
echo "Wrote $XRAY_CONFIG"

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
for pid in $(ps | awk '/[x]ray/ {print $1}'); do
  kill "$pid" 2>/dev/null || true
done
sleep 1
"$INIT_SCRIPT" start

echo "[7/7] Optional transparent mode"
if [ "$TRANSPARENT" = "--transparent" ]; then
  curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- enable || true
else
  echo "Transparent redirect is not enabled. To enable later:"
  echo "  curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- enable"
fi

echo
echo "Done. SOCKS test proxy: 127.0.0.1:10808"
echo "Run: curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh"
