#!/bin/sh
set -eu

DEVICE="${1:-}"
LABEL="${2:-ENTWARE}"

show_usage() {
  cat <<EOF
Usage:
  sh prepare-usb.sh /dev/sdX [LABEL]

Example:
  sh prepare-usb.sh /dev/sda ENTWARE

WARNING:
  This script formats the selected USB drive as ext4.
  All data on the selected device will be destroyed.

Recommended safer path:
  Format the USB drive from the Keenetic web interface, then install Entware/OPKG.
EOF
}

if [ -z "$DEVICE" ]; then
  show_usage
  echo
  echo "Detected block devices:"
  lsblk 2>/dev/null || true
  exit 1
fi

case "$DEVICE" in
  /dev/sd?|/dev/hd?|/dev/mmcblk?)
    ;;
  *)
    echo "Refusing suspicious device path: $DEVICE"
    echo "Pass a whole block device, for example /dev/sda."
    exit 1
    ;;
esac

if [ ! -b "$DEVICE" ]; then
  echo "Block device not found: $DEVICE"
  exit 1
fi

echo "Selected device: $DEVICE"
echo "Label: $LABEL"
echo
echo "Current block devices:"
lsblk 2>/dev/null || true
echo
echo "This will ERASE all data on $DEVICE."
printf "Type FORMAT to continue: "
read answer

if [ "$answer" != "FORMAT" ]; then
  echo "Cancelled."
  exit 1
fi

echo "[1/5] Unmounting existing partitions"
for part in "${DEVICE}"?*; do
  [ -e "$part" ] || continue
  umount "$part" 2>/dev/null || true
done

echo "[2/5] Creating one Linux partition"
if command -v parted >/dev/null 2>&1; then
  parted -s "$DEVICE" mklabel msdos
  parted -s "$DEVICE" mkpart primary ext4 1MiB 100%
else
  echo "parted is not installed. Install it with opkg or format via Keenetic UI."
  exit 1
fi

sleep 2
PART="${DEVICE}1"
if echo "$DEVICE" | grep -q 'mmcblk'; then
  PART="${DEVICE}p1"
fi

if [ ! -b "$PART" ]; then
  echo "Partition was not detected: $PART"
  echo "Unplug/replug the USB drive or format it via Keenetic UI."
  exit 1
fi

echo "[3/5] Formatting $PART as ext4"
if command -v mkfs.ext4 >/dev/null 2>&1; then
  mkfs.ext4 -F -L "$LABEL" "$PART"
else
  echo "mkfs.ext4 is not installed. Install e2fsprogs or format via Keenetic UI."
  exit 1
fi

echo "[4/5] Creating mount point"
mkdir -p /opt

echo "[5/5] Done"
echo
echo "USB partition is ready: $PART"
echo "Next steps:"
echo "  1. In Keenetic web UI, enable OPKG/Entware and select this drive."
echo "  2. Reboot the router if Keenetic asks."
echo "  3. Confirm /opt exists."
echo "  4. Run install.sh with the client's VLESS link."

