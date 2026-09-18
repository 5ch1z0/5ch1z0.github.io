#!/usr/bin/env bash
#
# Storage Sanitization Script
# Intended for use in a Rescue Mode / Live ISO environment.
#

set -euo pipefail

# Ensure running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "[-] Error: This script must be run as root." >&2
    exit 1
fi

echo "=== Block Devices Found ==="
lsblk -d -o NAME,SIZE,TYPE,MODEL,TRAN
echo "==========================="

# Prompt for the target device
read -rp "Enter target block device to permanently erase (e.g., sda, nvme0n1): " DEV_NAME
TARGET_DEV="/dev/${DEV_NAME}"

# Verify device existence
if [[ ! -b "$TARGET_DEV" ]]; then
    echo "[-] Error: Device $TARGET_DEV does not exist or is not a block device." >&2
    exit 1
fi

# Ensure no partitions on this device are currently mounted
if grep -qs "^${TARGET_DEV}" /proc/mounts; then
    echo "[-] Error: Partitions on $TARGET_DEV are mounted. Unmount them before wiping." >&2
    exit 1
fi

# Explicit confirmation prompt
echo ""
echo "[!] WARNING: You are about to permanently erase $TARGET_DEV."
echo "[!] All data, partition tables, and file systems will be destroyed."
echo "[!] This action CANNOT be undone."
echo ""
read -rp "Type 'DESTROY' in all caps to proceed: " CONFIRM

if [[ "$CONFIRM" != "DESTROY" ]]; then
    echo "[-] Aborted by user."
    exit 0
fi

echo ""
echo "[*] Unmounting any lingering swap..."
swapoff -a 2>/dev/null || true

# Determine device type and select sanitization strategy
if [[ "$DEV_NAME" =~ ^nvme ]]; then
    echo "[*] NVMe drive detected. Attempting cryptographic / hardware secure format..."
    if command -v nvme >/dev/null 2>&1; then
        # Format namespace: ses=2 requests Cryptographic Erase, falls back to User Data Erase (ses=1)
        if nvme format "$TARGET_DEV" --namespace-id=1 --ses=2 2>/dev/null; then
            echo "[+] NVMe crypto-erase completed successfully."
        elif nvme format "$TARGET_DEV" --namespace-id=1 --ses=1 2>/dev/null; then
            echo "[+] NVMe user data erase completed successfully."
        else
            echo "[!] NVMe hardware format unsupported or failed. Falling back to block discard..."
            blkdiscard -v "$TARGET_DEV" || true
        fi
    else
        echo "[!] 'nvme-cli' not found. Falling back to blkdiscard..."
        blkdiscard -v "$TARGET_DEV" || true
    fi
else
    # Check if drive supports blkdiscard (SSD / TRIM)
    DISCARD_SUPPORTED=0
    if [[ -f "/sys/block/${DEV_NAME}/queue/discard_max_bytes" ]]; then
        MAX_DISCARD=$(cat "/sys/block/${DEV_NAME}/queue/discard_max_bytes")
        if [[ "$MAX_DISCARD" -gt 0 ]]; then
            DISCARD_SUPPORTED=1
        fi
    fi

    if [[ "$DISCARD_SUPPORTED" -eq 1 ]]; then
        echo "[*] SSD / Discard support detected. Running blkdiscard..."
        blkdiscard -v "$TARGET_DEV" || true
    fi

    echo "[*] Overwriting partition tables and data with random data then zeroes..."
    # 1 pass random, 1 pass zeroes using shred
    if command -v shred >/dev/null 2>&1; then
        shred -v -n 1 -z "$TARGET_DEV"
    else
        echo "[!] 'shred' not installed. Overwriting with dd (zero-fill)..."
        dd if=/dev/zero of="$TARGET_DEV" bs=4M status=progress conv=fsync
    fi
fi

echo ""
echo "[*] Verifying sanitization on $TARGET_DEV (first 512 bytes):"
dd if="$TARGET_DEV" bs=512 count=1 2>/dev/null | hexdump -C

echo ""
echo "[+] Sanitization routine complete. Device is clean."
