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
#  REQUIREMENTS: root permisions and sanoid for snapshot management
#          BUGS: ---
#         NOTES: ad a alias like st to /usr/sbin/
#        AUTHOR: Dustin Hutto (Sysadmin), huttodustin@gmail.com
#  ORGANIZATION: -
#       CREATED: 09.10.2018 19:43:49
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

get_zfs_data() {
var_zfs_last_snapshot_all=$(zfs list -H -t snapshot -o name -S creation)
var_zfs_pool_status=$(zpool status | grep -E "(pool:|state:|scan:|errors:)" )
var_zfs_last_snapshot_hourly=$(awk -F_ '/hourly/{print $(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_daily=$(awk -F_ '/daily/{print $(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_monthly=$(awk -F_ '/monthly/{print $(NF-2)"_"$(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_yearly=$(awk -F_ '/yearly/{print $(NF-2)"_"$(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_snapshots_count=$(awk 'END {print NR}' <<< "$var_zfs_last_snapshot_all")
var_zfs_cap_mainpool=$(zpool list -H -o name,capacity)
}

printHeadLine(){
    eval printf %.0s# '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
    textsize=${#1}
    width=$(tput cols)
    span=$(((width + textsize) / 2))
    printf "%${span}s\\n" "$1"
    eval printf %.0s# '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
}

printf "\\ec"

printHeadLine "SYSTEM INFO"
printf "%-14s %s\n" "System:" "Debian"
printf "%-14s %s\n" "Kernel:" "$(uname -r)"
printf "%-14s %s\n" "Uptime:" "$(uptime -p)"
printf "%-14s %s\n\n" "CPU:" "$(< /proc/cpuinfo awk '/model name/{print $4, $5, $6, $7, $8, $9, $10; exit}')"

printf "## CPU Temperature ##\n\n"
sensors | awk -F\( '/Core|Package/{print $(NF-1)}'
printf "\n"
printf "## Memory usage ##\n\n"
free -h
printf "\n"

printHeadLine "ZFS STATUS"
get_zfs_data
printf "## Pool status ##\n\n"
awk 'BEGIN{OFS = "-"; print "Pool-Name""\t""Status""\t""Last-Scrub""\t""\t""Repaired-Errors""\t""Scrub-Errors""\t""Time""\t""Data-Errors"}; 
/pool/{ POOL=$2; next} /state/{STATE=$2; next} /scan/{SCAN1=$12"-"$13"-"$14"-"$15; SCAN2=$4; SCAN3=$8; SCAN4=$6; next} /error/{$1=""; print POOL"\t"STATE"\t"SCAN1"\t"SCAN2"\t"SCAN3"\t"SCAN4"\t"$0}' <<< "$var_zfs_pool_status" | column -t

printf "\n## Snapshots ##\n\n"
printf "Last zfs snapshots\n"
printf "%-10s %s\n" "HOURLY:" "$var_zfs_last_snapshot_hourly"
printf "%-10s %s\n" "DAILY:" "$var_zfs_last_snapshot_daily"
printf "%-10s %s\n" "MONTHLY:" "$var_zfs_last_snapshot_monthly"
printf "%-10s %s\n\n" "YEARLY:" "$var_zfs_last_snapshot_yearly"
printf "%-10s %s\n\n" "Total Snapshots:" "$var_zfs_snapshots_count"

printf "## Pool Capacity\'s  ##\n\n"
printf "%s\n" "$var_zfs_cap_mainpool"
