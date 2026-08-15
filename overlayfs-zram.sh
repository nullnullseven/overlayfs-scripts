#!/bin/bash
ZRAM_DEV=""
ZRAM_SIZE="2G"
LOWERDIR="/home"
OVERLAY_BASE="/run/home-overlay"
UPPERDIR="$OVERLAY_BASE/upper"
WORKDIR="$OVERLAY_BASE/work"
MOUNTPOINT="/home"

# Load zram module if not loaded
if ! lsmod | grep -q "^zram"; then
    modprobe zram num_devices=1 || modprobe zram
fi

# Wait for zram control interface
for _ in {1..10}; do
    if [ -d /sys/class/zram-control ]; then
        break
    fi
    sleep 0.1
done

# Find first free zram device
for i in /sys/block/zram*; do
    [ -e "$i" ] || continue
    if [ "$(cat "$i"/disksize)" = "0" ]; then
        ZRAM_DEV="/dev/$(basename "$i")"
        break
    fi
done

if [ -z "$ZRAM_DEV" ]; then
    # No free device; try to add one via hot_add
    if [ -f /sys/class/zram-control/hot_add ]; then
        idx=$(cat /sys/class/zram-control/hot_add)
        ZRAM_DEV="/dev/zram$idx"
    else
        echo "ERROR: no free zram device found and hot_add not available" >&2
        exit 1
    fi
fi

echo "Using $ZRAM_DEV"

# Configure compression and size
echo lz4 > /sys/block/$(basename "$ZRAM_DEV")/comp_algorithm 2>/dev/null || true
echo "$ZRAM_SIZE" > /sys/block/$(basename "$ZRAM_DEV")/disksize

# Format and mount zram as ext4 (needed for overlay upper+work)
mkfs.ext4 -q "$ZRAM_DEV"

mkdir -p "$OVERLAY_BASE"
mount -t ext4 "$ZRAM_DEV" "$OVERLAY_BASE"

# Prepare overlay directories
mkdir -p "$UPPERDIR" "$WORKDIR"

# Mount overlayfs
mount -t overlay overlay \
  -o lowerdir="$LOWERDIR",upperdir="$UPPERDIR",workdir="$WORKDIR" \
  "$MOUNTPOINT"
