#!/bin/bash
OVERLAY_BASE="/run/home-overlay"
LOWERDIR="/home"
UPPERDIR="$OVERLAY_BASE/upper"
WORKDIR="$OVERLAY_BASE/work"
MOUNTPOINT="/home"

# Create directories
mkdir -p "$UPPERDIR" "$WORKDIR"

# Mount tmpfs for overlay upper+work layers
mount -t tmpfs -o size=50%,mode=0755 tmpfs "$OVERLAY_BASE"

# Recreate upper/work inside tmpfs after mount
mkdir -p "$UPPERDIR" "$WORKDIR"

# Mount overlayfs
mount -t overlay overlay \
  -o lowerdir="$LOWERDIR",upperdir="$UPPERDIR",workdir="$WORKDIR" \
  "$MOUNTPOINT"
