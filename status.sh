#!/bin/sh -
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
#         NOTES: ad a alias like st to /usr/local/sbin/
#        AUTHOR: Tenyun (Sysadmin), tenyun@disroot.org
#  ORGANIZATION: -
#       CREATED: 09.10.2018 19:43:49
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

ZFS_BIN=$(whereis -b zfs | awk '{print $2}')
ZPOOL_BIN=$(whereis -b zpool | awk '{print $2}')

get_zfs_data() {
var_zfs_last_snapshot_all=$($ZFS_BIN list -H -t snapshot -o name -S creation)
var_zfs_pool_status=$($ZPOOL_BIN status | grep -E "(pool:|state:|scan:|errors:)" )
var_zfs_last_snapshot_hourly=$(awk -F_ '/hourly/{print $(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_daily=$(awk -F_ '/daily/{print $(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_monthly=$(awk -F_ '/monthly/{print $(NF-2)"_"$(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_last_snapshot_yearly=$(awk -F_ '/yearly/{print $(NF-2)"_"$(NF-1);exit;}' <<< "$var_zfs_last_snapshot_all")
var_zfs_snapshots_count=$(awk 'END {print NR}' <<< "$var_zfs_last_snapshot_all")
var_zfs_cap_mainpool=$($ZPOOL_BIN list -H -o name,capacity)
}

printHeadLine(){
    textsize=${#1}
        span=$(((textsize + 60) / 2))
        printf '%.0s=' {1..60}; echo
    printf "%${span}s\\n" "$1"
    printf '%.0s=' {1..60}; echo
}

printf "\\ec"

printHeadLine "SYSTEM INFO"
printf "%-14s %s\n" "System:" "$(awk -F'"' '/PRETTY_NAME/ {print $2}' /etc/os-release)"
printf "%-14s %s\n" "Kernel:" "$(uname -r)"
printf "%-14s %s\n" "Uptime:" "$(uptime -p)"
printf "%-14s %s\n\n" "CPU:" "$(< /proc/cpuinfo awk '/model name/{print $4, $5, $6, $7, $8, $9, $10; exit}')"

printf "## CPU Temperature ##\n\n"
cpu_count=$(lscpu | awk -F: '/NUMA\ node\(s\)/{print $2-1}')

for i in $(seq 0 "$cpu_count")
do
	cpu[$i]=$(sensors -A -- *-isa-000"$i" | awk -F\( '/Core|Package/{print $(NF-1)}')
done

if [ "$cpu_count" -lt 1 ]
then
	printf "%s\n" "${cpu[0]}"
	printf "\n"
elif [ "$cpu_count" -ge 1 ]
then
	for v in $(seq 0 2 "$cpu_count")
	do
		paste <(printf "%s" "${cpu[$v]}") <(printf "%s" "${cpu[$v + 1]}")
		printf "\n"
	done
fi

printf "## Memory usage ##\n\n"
var_mem_info=$(free -hw)
awk '/Mem/{printf "%-14s %-7s %-14s %s\n%-14s %-7s %-14s %s\n", "Total:", $2, "Used:", $3, "Free:", $4, "Shared:", $5}' <<< "$var_mem_info"
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
