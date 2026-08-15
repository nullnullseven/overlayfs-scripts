#!/bin/bash
OVERLAY_BASE="/run/home-overlay"
CRYPT_NAME="home-overlay-crypt"
LOWERDIR="/home"
MOUNTPOINT="/home"
SIZE="2G"
CIPHER="aes-xts-plain64"
KEY_SIZE=512

# Check if already mounted
if findmnt -n -o FSTYPE "$MOUNTPOINT" 2>/dev/null | grep -q overlay; then
    echo "Overlay already active on $MOUNTPOINT"
    exit 0
fi

# Require root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Need root" >&2
    exit 1
fi

# Create tmpfs backing store for container file
mkdir -p "$OVERLAY_BASE"
mount -t tmpfs -o size=1100M,mode=0700,noexec,nodev,nosuid,noatime tmpfs "$OVERLAY_BASE"

# Create 2G sparse file
truncate -s "$SIZE" "$OVERLAY_BASE/container.img"

# Set up loop device
LOOP_DEV=$(losetup --find --show --sector-size 512 "$OVERLAY_BASE/container.img")

# Ephemeral key in memory only
KEYFILE=$(mktemp -p /dev/shm .key.XXXXXX)
dd if=/dev/urandom of="$KEYFILE" bs=64 count=1 status=none
chmod 600 "$KEYFILE"

# Open plain dm-crypt (no LUKS header)
cryptsetup open --type plain \
    --cipher "$CIPHER" \
    --key-size "$KEY_SIZE" \
    --key-file "$KEYFILE" \
    "$LOOP_DEV" "$CRYPT_NAME"

# Key no longer needed - destroy it
shred -u "$KEYFILE" 2>/dev/null || rm -f "$KEYFILE"
unset KEYFILE

# Filesystem on encrypted device
mkfs.ext4 -F -q -m 0 -O ^has_journal /dev/mapper/"$CRYPT_NAME"

# Mount encrypted volume ON TOP OF tmpfs
# (container.img remains alive because loop device holds it)
mount -o noatime,nodiratime,noexec,nodev,nosuid /dev/mapper/"$CRYPT_NAME" "$OVERLAY_BASE"

# Directories for overlay
mkdir -p "$OVERLAY_BASE/upper" "$OVERLAY_BASE/work"

# Final overlay mount
mount -t overlay overlay \
    -o lowerdir="$LOWERDIR",upperdir="$OVERLAY_BASE/upper",workdir="$OVERLAY_BASE/work",noatime,nodiratime \
    "$MOUNTPOINT"
