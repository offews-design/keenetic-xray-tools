#!/bin/sh
set -eu

BACKUP_ROOT="/opt/root/xray-backups"
TS="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo manual)"
DEST="$BACKUP_ROOT/$TS"

mkdir -p "$DEST"

copy_if_exists() {
  src="$1"
  name="$2"
  if [ -e "$src" ]; then
    cp -a "$src" "$DEST/$name"
    echo "Saved: $src -> $DEST/$name"
  fi
}

copy_if_exists "/opt/etc/xray/config.json" "config.json"
copy_if_exists "/opt/etc/init.d/S24xray" "S24xray"
copy_if_exists "/opt/bin/xray" "xray"

echo "Backup directory: $DEST"

