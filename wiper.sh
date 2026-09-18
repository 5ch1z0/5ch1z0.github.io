#!/usr/bin/env bash
#
# In-Memory Live Disk Eraser
# Runs from an active TTY / SSH session.
# Pre-loads tools to RAM, breaks disk dependencies, and destroys storage blocks.
#

set -uo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "[-] Error: This script must be executed as root." >&2
    exit 1
fi

echo "=== ACTIVE BLOCK DEVICES ==="
lsblk -d -o NAME,SIZE,TYPE,MODEL
echo "============================"

read -rp "Enter the primary disk to wipe (e.g., sda, vda, nvme0n1): " TARGET_NAME
TARGET_DEV="/dev/${TARGET_NAME}"

if [[ ! -b "$TARGET_DEV" ]]; then
    echo "[-] Error: Device $TARGET_DEV does not exist or is not a block device." >&2
    exit 1
fi

echo ""
echo "[!] WARNING: You are about to permanently erase $TARGET_DEV from a live session."
echo "[!] The server will crash, the session will terminate, and the OS will be destroyed."
echo ""
read -rp "Type 'PERMANENTLY DESTROY' to proceed: " CONFIRM

if [[ "$CONFIRM" != "PERMANENTLY DESTROY" ]]; then
    echo "[-] Aborted by user."
    exit 0
fi

echo "[*] Setting up RAM-only execution space..."

# Create an isolated tmpfs mount
RAM_DIR="/tmp/ramwipe"
mkdir -p "$RAM_DIR"
mount -t tmpfs -o size=256M tmpfs "$RAM_DIR"

# Copy essential tools and dynamic libraries into RAM
mkdir -p "$RAM_DIR/bin" "$RAM_DIR/lib" "$RAM_DIR/lib64"

# Locate necessary binaries
BINARIES=( "dd" "sync" "sleep" "sh" "bash" "reboot" "echo" )
for bin in "${BINARIES[@]}"; do
    BIN_PATH=$(command -v "$bin" 2>/dev/null || true)
    if [[ -n "$BIN_PATH" ]]; then
        cp -a "$BIN_PATH" "$RAM_DIR/bin/"
        # Copy shared libraries used by these binaries into RAM
        ldd "$BIN_PATH" 2>/dev/null | grep -o '/[^ ]*' | while read -r lib; do
            if [[ -f "$lib" ]]; then
                LIB_DIR=$(dirname "$lib")
                mkdir -p "$RAM_DIR$LIB_DIR"
                cp -u "$lib" "$RAM_DIR$LIB_DIR/" 2>/dev/null || true
            fi
        done
    fi
done

# Check if static busybox is available (ideal for surviving root destruction)
if command -v busybox >/dev/null 2>&1; then
    cp -a "$(command -v busybox)" "$RAM_DIR/bin/"
fi

# Ensure storage writes are flushed to disk before starting
sync
echo 3 > /proc/sys/vm/drop_caches

# Write the self-contained execution payload to RAM
cat << 'EOF' > "$RAM_DIR/payload.sh"
#!/bin/sh
export PATH="/bin:/sbin"

# Terminate logging and background services to minimize disk operations
for s in rsyslog syslog-ng systemd-journald; do
    pkill -9 "$s" 2>/dev/null
done

# Overwrite partition tables and MBR / GPT headers first
echo "[*] Zeroing partition headers..."
dd if=/dev/zero of="$TARGET_DEV" bs=1M count=100 conv=fsync 2>/dev/null

# Overwrite storage with zero-fill stream
echo "[*] Commencing continuous disk overwrite on $TARGET_DEV..."
dd if=/dev/zero of="$TARGET_DEV" bs=4M status=none conv=fsync &
WIPE_PID=$!

# Wait for completion or until system memory becomes unstable
wait $WIPE_PID 2>/dev/null

# Force raw kernel reboot/halt if reachable
echo 1 > /proc/sys/kernel/sysrq 2>/dev/null
echo b > /proc/sysrq-trigger 2>/dev/null
EOF

chmod +x "$RAM_DIR/payload.sh"

echo "[*] Handing off execution to RAM-backed script..."
echo "[*] Disk overwrite is beginning. Connection will drop momentarily."

# Pass environment variables and transfer execution entirely to memory
env TARGET_DEV="$TARGET_DEV" chroot "$RAM_DIR" /bin/sh /payload.sh
