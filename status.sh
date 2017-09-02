 #!/bin/bash

#
# Dieses Script gibt einen Überblick über den PVE Server
# (hostname, ip, zfs-filesystem, zfs-snapshots, etc)
#

var_os=Debian
var_kernel=`uname -r`
var_uptime=`uptime -p`
var_cpu=`cat /proc/cpuinfo | grep "model name" -m1 | awk '{ print $4, $5, $6, $7, $8, $9, $10 }'`

var_zfs_last_snapshot_all=$(zfs list -H -t snapshot -o name -S creation)
var_zfs_pool_status=$(zpool status | grep -E "(pool:|state:|scan:|errors:)" )
var_zfs_last_snapshot_hourly=$(echo "$var_zfs_last_snapshot_all" | grep hourly | head -1 | awk -F_ '{print $(NF-1)}')
var_zfs_last_snapshot_daily=$(echo "$var_zfs_last_snapshot_all" | grep daily | head -1 | awk -F_ '{print $(NF-1)}')
var_zfs_last_snapshot_monthly=$(echo "$var_zfs_last_snapshot_all" | grep monthly | head -1 | awk -F_ '{print $(NF-2)"_"$(NF-1)}')
var_zfs_last_snapshot_yearly=$(echo "$var_zfs_last_snapshot_all" | grep yearly | head -1 | awk -F_ '{print $(NF-2)"_"$(NF-1)}')
var_zfs_snapshots_count=$(echo "$var_zfs_last_snapshot_all" | nl)
var_zfs_cap_mainpool=$(zpool list -H -o name,capacity)

printf "\ec"

echo "###########################################################################"
echo "###				System-Info				###"
echo -e "###########################################################################\n"
echo -e System OS:'\t'$var_os
echo -e Kernel:'\t\t'$var_kernel
echo -e Uptime:'\t\t'$var_uptime
echo -e CPU:'\t\t'$var_cpu
echo -e ""
echo "## Temperaturen CPU ##"
echo -e ""
sensors | tail -n10 | head -n5 | awk '{ print $1,$2,$3,$4 }' | cut -d "(" -f 1 | column -s : -t
echo -e ""
echo "## Speicherauslastung ##"
echo ""
free -h
echo -e ""

echo "###########################################################################"
echo "###                            ZFS-Filesystem                           ###"
echo -e "###########################################################################\n"
echo "## Pool-Status ##"
echo -e ""
echo "$var_zfs_pool_status" | awk 'BEGIN{OFS = "-"; print "Pool-Name""\t""Status""\t""Last-Scrub""\t""\t""Repaired-Errors""\t""Scrub-Errors""\t""Time""\t""Data-Errors"}; /pool/{ POOL=$2; next} /state/{STATE=$2; next} /scan/{SCAN1=$12"-"$13"-"$14"-"$15; SCAN2=$4; SCAN3=$8; SCAN4=$6; next} /error/{$1=""; print POOL"\t"STATE"\t"SCAN1"\t"SCAN2"\t"SCAN3"\t"SCAN4"\t"$0}' | column -t
#echo -e Pool-Name'\t'Status'\t'Last Scrub'\t\t'Repaired-Errors'\t'Scrub-Errors'\t'Time
#echo awk '{print "Pool-Name","\t","Status","\t","Last Scrub","\t","\t","Repaired-Errors","\t","Scrub-Errors","\t","Time","\n"}'
#echo $var_zfs_pool_status | awk '{print "Pool-Name","\t","Status","\t","Last Scrub","\t","\t","Repaired-Errors","\t","Scrub-Errors","\t","Time","\n",$2,"\t",$4,"\t",$16,$17,$18,$19,"\t",$8,"\t","\t","\t",$12,"\t","\t",$10}'
#zpool status mainpool | grep -E "(pool:|state:|scan:|errors:)"
#echo -e ""
#echo -e $var_zfs_pool_status_rpool_format
#zpool status rpool | grep -E "(pool:|state:|scan:|errors:)"
echo -e ""

#echo "## zpool iostat ##"
#echo -e ""
#zpool iostat mainpool
#echo -e ""

echo "## Snapshots ##"
echo -e ""
echo Lätzte Snapshots
echo -e "Stündlich \tTäglich \tMonatlich \t\tJährlich"
echo -e "$var_zfs_last_snapshot_hourly \t$var_zfs_last_snapshot_daily \t$var_zfs_last_snapshot_monthly \t$var_zfs_last_snapshot_yearly"
echo -e ""
echo Anzahl aller Snapschots: $var_zfs_snapshots_count
echo -e ""

echo "## mainpool Capacity  ##"
echo -e ""
echo -e Belegter Speicherplatz:'\n'$"var_zfs_cap_mainpool"
