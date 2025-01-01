#!/bin/bash -
#===============================================================================
#
#          FILE: status.sh
#
#         USAGE: ./status.sh
#
#   DESCRIPTION: System status script for PROXMOX PVE
#
#       OPTIONS: ---
#  REQUIREMENTS: cv4pve-autosnap for snapshot management
#          BUGS: ---
#         NOTES: add a alias like st to /usr/local/sbin/
#        AUTHOR: Tenyun (Sysadmin), tenyun@disroot.org
#  ORGANIZATION: -
#       CREATED: 09.10.2018 19:43:49
#      REVISION:  1.2.0
#===============================================================================

set -o nounset # Treat unset variables as an error

#ZFS_BIN=$(whereis -b zfs | awk '{print $2}')
ZPOOL_BIN=$(whereis -b zpool | awk '{print $2}')
SNAP_HOST="127.0.0.1"
CRON_SCRIPT="/etc/cron.d/snapshot"
# Set API_TOKEN to your snapshot user created in proxmox
# API_TOKEN="snapuser@REALM!TOKENID=UUID"
API_TOKEN=""
# Function to extract API_TOKEN from CRON_SCRIPT
extract_token_from_script() {
    if [[ -e "$CRON_SCRIPT" && -f "$CRON_SCRIPT" ]]; then
        # Extract token from non-commented lines
        local token
        token=$(awk -F'"' '!/^#/ && /API_TOKEN/ {print $2; exit}' "$CRON_SCRIPT")
        if [[ -n "$token" ]]; then
            echo "$token"
        else
            printf "Error: API_TOKEN not found in %s\n" "$CRON_SCRIPT"
            exit 1
        fi
    else
        printf "Error: CRON_SCRIPT not found: %s\n" "$CRON_SCRIPT"
        exit 1
    fi
}
 
if [[ -z "$API_TOKEN" ]]; then
    # If API_TOKEN is not set try to extract it from CRON_SCRIPT
    if [[ -e "$CRON_SCRIPT" && -f "$CRON_SCRIPT" ]]; then
        API_TOKEN=$(extract_token_from_script)
    else
        printf "Error: API_TOKEN is not set and CRON_SCRIPT does not exist.\n"
        exit 1                                                                                                                                                                                      
    fi                                                                                                                                                                                              
else                                                                                                                                                                                                
    # If API_TOKEN is set still check if CRON_SCRIPT is available
    if [[ -e "$CRON_SCRIPT" && -f "$CRON_SCRIPT" ]]; then
        # Optionally update API_TOKEN from the script
        API_TOKEN=$(extract_token_from_script)
    fi
fi

printHeadLine() {
	textsize=${#1}
	span=$(((textsize + 60) / 2))
	printf '%.0s=' {1..60}
	echo
	printf "%${span}s\\n" "$1"
	printf '%.0s=' {1..60}
	echo
}

printf "\\ec"

printHeadLine "SYSTEM INFO"
printf "%-14s %s\n" "System:" "$(awk -F'"' '/PRETTY_NAME/ {print $2}' /etc/os-release)"
printf "%-14s %s\n" "Kernel:" "$(uname -r)"
printf "%-14s %s\n" "Uptime:" "$(uptime -p)"
printf "%-14s %s\n\n" "CPU:" "$(awk </proc/cpuinfo '/model name/{print $4, $5, $6, $7, $8, $9, $10; exit}')"

printf "## CPU Temperature ##\n\n"
# Determine CPU vendor (Intel or AMD)
cpu_vendor=$(lscpu | awk -F: '/Vendor ID/ {print $2}' | tr -d '[:space:]')

# Get the number of NUMA nodes (number of sockets - 1)
cpu_count=$(lscpu | awk -F: '/NUMA\ node\(s\)/{print $2-1}')

# Initialize temperature array
declare -a cpu

# Check if the CPU is AMD or Intel
if [ "$cpu_vendor" == "AuthenticAMD" ]; then
    # For AMD CPUs, we need to check if we have individual core temperatures or just package temperature
    # Check if the Tctl temperature is available (if it is, it's likely the package temperature)
    if sensors | awk '/Tctl/' > /dev/null; then
        # If only Tctl (package) temperature is available
        for i in $(seq 0 "$cpu_count"); do
            cpu[i]=$(sensors | awk -F': ' '/Tctl/{print }' | head -n 1)  # Get Tctl (package) temperature
        done
    else
        # If individual core temperatures are available
        for i in $(seq 0 "$cpu_count"); do
            cpu[i]=$(sensors -A | grep -i "core $i" | awk -F'[\+\ ]' '{print $2}')
        done
    fi
else
    # For Intel CPUs, query the sensors for core and package temperatures
    for i in $(seq 0 "$cpu_count"); do
        cpu[i]=$(sensors -A | awk -F\( "/Core $i|Package/{print \$(NF-1)}")
    done
fi

# Output temperature information
if [ "$cpu_count" -lt 1 ]; then
    printf "%s\n" "${cpu[0]}"
    printf "\n"
elif [ "$cpu_count" -ge 1 ]; then
    # Pair temperatures for each socket (e.g., socket 0, socket 1, etc.)
    for v in $(seq 0 2 "$cpu_count"); do
        paste <(printf "%s" "${cpu[$v]}") <(printf "%s" "${cpu[$v + 1]}")
        printf "\n"
    done
fi
printf "## Memory usage ##\n\n"
var_mem_info=$(free -hw)
awk '/Mem/{printf "%-14s %-7s %-14s %s\n%-14s %-7s %-14s %s\n", "Total:", $2, "Used:", $3, "Free:", $4, "Shared:", $5}' <<<"$var_mem_info"
printf "\n"

printHeadLine "ZFS STATUS"
printf "## Pool status ##\n\n"
$ZPOOL_BIN status -x

# Print the initial placeholders for snapshots and pool capacity
printf "\n## Snapshots ##\n\n"
printf "Last zfs snapshots (Timezone UTC)\n"
# Save cursor position
tput sc
printf "%-10s %s\n" "HOURLY:" "Loading..."
printf "%-10s %s\n" "DAILY:" "Loading..."
printf "%-10s %s\n" "WEEKLY:" "Loading..."
printf "%-10s %s\n\n" "MONTHLY:" "Loading..."
printf "%-10s %s\n\n" "Total Snapshots:" "Loading..."
printf "## Pool Capacity's  ##\n\n"
printf "%s\n" "Loading..."

var_zfs_last_snapshot_all=$(cv4pve-autosnap --host="$SNAP_HOST" --api-token="$API_TOKEN" --vmid="all" status --output="Markdown")

# Check if the command was successful
if [ $? -ne 0 ]; then
  printf "Error: Failed to fetch ZFS snapshots.\n"
  exit 1
fi
var_zfs_cap_mainpool=$($ZPOOL_BIN list -H -o name,capacity)

# Restore cursor position and update the snapshot and pool capacity information
tput rc

# Update snapshot details
var_zfs_last_snapshot_hourly=$(awk -F"|" '/hourly/ {a=$4} END{print a}' <<<"$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_daily=$(awk -F"|" '/daily/ {a=$4} END{print a}' <<<"$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_weekly=$(awk -F"|" '/weekly/ {a=$4} END{print a}' <<<"$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_monthly=$(awk -F"|" '/monthly/ {a=$4} END{print a}' <<<"$var_zfs_last_snapshot_all")
var_zfs_snapshots_count=$(awk 'END {print NR-2}' <<<"$var_zfs_last_snapshot_all")

# Overwrite the lines with the actual data
printf "\033[K%-10s %s\n" "HOURLY:" "$var_zfs_last_snapshot_hourly"
printf "\033[K%-10s %s\n" "DAILY:" "$var_zfs_last_snapshot_daily"
printf "\033[K%-10s %s\n" "WEEKLY:" "$var_zfs_last_snapshot_weekly"
printf "\033[K%-10s %s\n\n" "MONTHLY:" "$var_zfs_last_snapshot_monthly"
printf "\033[K%-10s %s\n\n" "Total Snapshots:" "$var_zfs_snapshots_count"
printf "\033[K## Pool Capacity's  ##\n\n"
printf "\033[K%s\n" "$var_zfs_cap_mainpool"
