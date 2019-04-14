# Status script for Proxmox Virtual Environment (PVE)

## Requirements
* one or more zfs pools
* [Sanoid] (https://github.com/jimsalterjrs/sanoid) for snapshot management

## Installation

Clone the repository:

	https://gitea.omniaty.ddnss.de/Tenyun/pve-status.git

Link status.sh to e.g.:

	ln -s /path/to/pve-status/status.sh /usr/sbin/st

## Example

	============================================================
	                        SYSTEM INFO
	============================================================
	System:        Debian GNU/Linux 9 (stretch)
	Kernel:        4.15.18-11-pve
	Uptime:        up 7 weeks, 4 days, 21 hours, 37 minutes
	CPU:           Intel(R) Xeon(R) CPU E3-1240 v6 @ 3.70GHz

	## CPU Temperature ##

	Package id 0:  +37.0°C
	Core 0:        +37.0°C
	Core 1:        +34.0°C
	Core 2:        +32.0°C
	Core 3:        +36.0°C

	## Memory usage ##

	Total:         31G     Used:          9.7G
	Free:          18G     Shared:        570M

	============================================================
	                         ZFS STATUS
	============================================================
	## Pool status ##

	Pool-Name  Status  Last-Scrub            Repaired-Errors  Scrub-Errors  Time  Data-Errors
	hddpool    ONLINE  Apr-14-06:48:47-2019  0B               0             0h1m  -No-known-data-errors
	rpool      ONLINE  Apr-14-06:49:22-2019  0B               0             0h0m  -No-known-data-errors
	ssdpool    ONLINE  Apr-14-06:50:56-2019  0B               0             0h0m  -No-known-data-errors

	## Snapshots ##

	Last zfs snapshots
	HOURLY:    19:00:01
	DAILY:     00:00:01
	MONTHLY:   2019-04-01_00:00:01
	YEARLY:    2019-02-17_15:05:01

	Total Snapshots: 1072

	## Pool Capacity's  ##

	hddpool	0%
	rpool	1%
	ssdpool	2%

## TODO

* Change the output width and format of the "Pool status" section to match the rest of the output
