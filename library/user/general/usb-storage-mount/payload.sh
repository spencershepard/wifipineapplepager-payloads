#!/bin/bash
# Title: USB Storage Mount
# Description: Mounts and unmounts the usb storage device.
# Author: RootJunky
# Version: 1

MOUNTPOINT="/mnt/usb"
DEVICE="/dev/sda1"

# Create mount point if it doesn't exist
mkdir -p "$MOUNTPOINT"

# Check if device is mounted
if mount | grep -q "$DEVICE"; then
    echo "$DEVICE is already mounted. Unmounting..."
    umount "$DEVICE"
    LOG "USB device unmounted"
    echo "Unmounted $DEVICE"
else
    echo "$DEVICE is not mounted. Mounting..."
    mount "$DEVICE" "$MOUNTPOINT"
    LOG "USB device mounted at /mnt/usb/"
    echo "Mounted $DEVICE at $MOUNTPOINT"
fi
