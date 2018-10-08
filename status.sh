#!/bin/bash

#
# Dieses Script gibt einen Überblick über den PVE Server
# (hostname, ip, zfs-filesystem, zfs-snapshots, etc)
#

get_zfs_data() {
var_zfs_last_snapshot_all=$(zfs list -H -t snapshot -o name -S creation)
var_zfs_pool_status=$(zpool status | grep -E "(pool:|state:|scan:|errors:)" )
var_zfs_last_snapshot_hourly=$(echo "$var_zfs_last_snapshot_all" | awk -F_ '/hourly/{h=$(NF-1)} NR==1{print h}')
var_zfs_last_snapshot_daily=$(echo "$var_zfs_last_snapshot_all" | awk -F_ '/daily/{d=$(NF-1)} NR==1{print d}')
var_zfs_last_snapshot_monthly=$(echo "$var_zfs_last_snapshot_all" | awk -F_ '/hourly/{h=$(NF-2)"_"$(NF-1)} NR==1{print h}')
var_zfs_last_snapshot_yearly=$(echo "$var_zfs_last_snapshot_all" | awk -F_ '/yearly/{y=$(NF-2)"_"$(NF-1)} NR==1{print y}')
var_zfs_snapshots_count=$(echo "$var_zfs_last_snapshot_all" | awk 'END {print NR}')
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

printHeadLine "System-Info"
echo -e System OS:'\t'"Debian"
echo -e Kernel:'\t\t'"$(uname -r)"
echo -e Uptime:'\t\t'"$(uptime -p)"
echo -e CPU:'\t\t'"$(< /proc/cpuinfo awk '/model name/{print $4, $5, $6, $7, $8, $9, $10; exit}')"
echo -e ""
echo "## Temperaturen CPU ##"
echo -e ""
sensors | awk '/Core|Package/' | cut -d "(" -f 1
echo -e ""
echo "## Speicherauslastung ##"
echo ""
free -h
echo -e ""

printHeadLine "ZFS-Filesystem"
get_zfs_data
echo "## Pool-Status ##"
echo -e ""
echo "$var_zfs_pool_status" | awk 'BEGIN{OFS = "-"; print "Pool-Name""\t""Status""\t""Last-Scrub""\t""\t""Repaired-Errors""\t""Scrub-Errors""\t""Time""\t""Data-Errors"}; /pool/{ POOL=$2; next} /state/{STATE=$2; next} /scan/{SCAN1=$12"-"$13"-"$14"-"$15; SCAN2=$4; SCAN3=$8; SCAN4=$6; next} /error/{$1=""; print POOL"\t"STATE"\t"SCAN1"\t"SCAN2"\t"SCAN3"\t"SCAN4"\t"$0}' | column -t
echo -e ""

echo "## Snapshots ##"
echo -e ""
echo Letzte Snapshots
echo -e "Stündlich \\tTäglich \\tMonatlich \\t\\tJährlich"
echo -e "$var_zfs_last_snapshot_hourly \\t$var_zfs_last_snapshot_daily \\t$var_zfs_last_snapshot_monthly \\t$var_zfs_last_snapshot_yearly"
echo -e ""
echo Anzahl aller Snapschots: "$var_zfs_snapshots_count"
echo -e ""

echo "## mainpool Capacity  ##"
echo -e ""
echo -e Belegter Speicherplatz:'\n'"$var_zfs_cap_mainpool"
