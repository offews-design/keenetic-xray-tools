#!/bin/sh
set -eu

MODE="${1:-}"
ARG2="${2:-}"
ARG3="${3:-}"

show_usage() {
  cat <<EOF
Usage:
  sh prepare-usb.sh --list
  sh prepare-usb.sh --auto [LABEL]
  sh prepare-usb.sh /dev/sdX [LABEL]

Examples:
  sh prepare-usb.sh --list
  sh prepare-usb.sh --auto ENTWARE
  sh prepare-usb.sh /dev/sda ENTWARE

WARNING:
  This script formats the selected removable USB drive as ext4.
  All data on the selected device will be destroyed.

Recommended safer path:
  Format the USB drive from the Keenetic web interface, then install Entware/OPKG.
EOF
}

device_base() {
  basename "$1" | sed 's/[0-9]*$//' | sed 's/p$//'
}

sys_block_name() {
  basename "$1"
}

is_block_device() {
  [ -b "$1" ]
}

is_removable() {
  dev="$(sys_block_name "$1")"
  [ -r "/sys/block/$dev/removable" ] && [ "$(cat "/sys/block/$dev/removable")" = "1" ]
}

is_usb_device() {
  dev="$(sys_block_name "$1")"
  readlink -f "/sys/block/$dev/device" 2>/dev/null | grep -qi '/usb' && return 0
  udevadm info -q property -n "$1" 2>/dev/null | grep -qi '^ID_BUS=usb' && return 0
  return 1
}

is_mounted_critical() {
  dev="$1"
  base="$(sys_block_name "$dev")"
  mount | awk '{print $1 " " $3}' | grep -E "^/dev/${base}[0-9p]* /( |$)|^/dev/${base}[0-9p]* /opt( |$)" >/dev/null 2>&1
}

list_usb_devices() {
  found=0
  for sysdev in /sys/block/sd* /sys/block/mmcblk*; do
    [ -e "$sysdev" ] || continue
    dev="/dev/$(basename "$sysdev")"
    [ -b "$dev" ] || continue
    removable="no"
    usb="no"
    is_removable "$dev" && removable="yes"
    is_usb_device "$dev" && usb="yes"
    if [ "$removable" = "yes" ] || [ "$usb" = "yes" ]; then
      found=1
      size="$(cat "$sysdev/size" 2>/dev/null || echo 0)"
      model="$(cat "$sysdev/device/model" 2>/dev/null | tr -s ' ' ' ' || true)"
      vendor="$(cat "$sysdev/device/vendor" 2>/dev/null | tr -s ' ' ' ' || true)"
      printf '%s removable=%s usb=%s sectors=%s vendor="%s" model="%s"\n' "$dev" "$removable" "$usb" "$size" "$vendor" "$model"
    fi
  done
  [ "$found" = "1" ]
}

auto_device() {
  tmp="/tmp/prepare-usb-devices.$$"
  list_usb_devices | awk '{print $1}' > "$tmp" || true
  count="$(wc -l < "$tmp" | tr -d ' ')"
  if [ "$count" = "0" ]; then
    rm -f "$tmp"
    echo "No removable/USB block device found." >&2
    exit 1
  fi
  if [ "$count" != "1" ]; then
    echo "More than one removable/USB device found. Refusing --auto." >&2
    cat "$tmp" >&2
    rm -f "$tmp"
    exit 1
  fi
  cat "$tmp"
  rm -f "$tmp"
}

if [ "$MODE" = "--help" ] || [ "$MODE" = "-h" ]; then
  show_usage
  exit 0
fi

if [ "$MODE" = "--list" ]; then
  echo "Detected removable/USB block devices:"
  list_usb_devices || echo "none"
  echo
  echo "All block devices:"
  lsblk 2>/dev/null || true
  exit 0
fi

if [ "$MODE" = "--auto" ]; then
  DEVICE="$(auto_device)"
  LABEL="${ARG2:-ENTWARE}"
elif [ -n "$MODE" ]; then
  DEVICE="$MODE"
  LABEL="${ARG2:-ENTWARE}"
else
  show_usage
  echo
  echo "Detected removable/USB block devices:"
  list_usb_devices || echo "none"
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

if ! is_block_device "$DEVICE"; then
  echo "Block device not found: $DEVICE"
  exit 1
fi

if ! is_removable "$DEVICE" && ! is_usb_device "$DEVICE"; then
  echo "Refusing to format non-removable/non-USB device: $DEVICE"
  echo "Use --list to inspect detected USB drives."
  exit 1
fi

if is_mounted_critical "$DEVICE"; then
  echo "Refusing to format $DEVICE because / or /opt is mounted from it."
  exit 1
fi

echo "Selected removable/USB device: $DEVICE"
echo "Label: $LABEL"
echo
echo "Detected removable/USB devices:"
list_usb_devices || true
echo
echo "All block devices:"
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
elif command -v fdisk >/dev/null 2>&1; then
  {
    echo o
    echo n
    echo p
    echo 1
    echo
    echo
    echo w
  } | fdisk "$DEVICE"
else
  echo "Neither parted nor fdisk is installed. Format via Keenetic UI."
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

