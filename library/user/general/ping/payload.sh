#!/bin/bash
# Title:                Ping
# Description:          Pings a target IP address or hostname and logs the results
# Author:               eflubacher
# Version:              1.0

# Options
LOOTDIR=/root/loot/ping
PING_COUNT=4

# Prompt user for target IP address or hostname
LOG "Launching ping..."
target=$(TEXT_PICKER "Enter target host" "8.8.8.8")
case $? in
    $DUCKYSCRIPT_CANCELLED)
        LOG "User cancelled"
        exit 1
        ;;
    $DUCKYSCRIPT_REJECTED)
        LOG "Dialog rejected"
        exit 1
        ;;
    $DUCKYSCRIPT_ERROR)
        LOG "An error occurred"
        exit 1
        ;;
esac

# Prompt user for number of pings (optional)
ping_count=$(NUMBER_PICKER "Number of pings" $PING_COUNT)
case $? in
    $DUCKYSCRIPT_CANCELLED)
        LOG "User cancelled"
        exit 1
        ;;
    $DUCKYSCRIPT_REJECTED)
        LOG "Using default ping count: $PING_COUNT"
        ping_count=$PING_COUNT
        ;;
    $DUCKYSCRIPT_ERROR)
        LOG "An error occurred, using default ping count: $PING_COUNT"
        ping_count=$PING_COUNT
        ;;
esac

# Create loot destination if needed
mkdir -p $LOOTDIR
# Sanitize target for filename (replace invalid chars with underscores)
safe_target=$(echo "$target" | tr '/: ' '_')
lootfile=$LOOTDIR/$(date -Is)_$safe_target

LOG "Pinging $target ($ping_count times)..."
LOG "Results will be saved to: $lootfile\n"

# Run ping and save to file, also log each line
ping -c $ping_count $target | tee $lootfile | tr '\n' '\0' | xargs -0 -n 1 LOG

LOG "\nPing complete!"

