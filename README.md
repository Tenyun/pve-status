# Status script for Proxmox Virtual Environment (PVE)

## Requirements
* one or more zfs pools
* [cv4pve-autosnap] (https://github.com/Corsinvest/cv4pve-autosnap) for snapshot management

## Installation

Clone the repository:
```
	https://gitea.omniaty.ddnss.de/Tenyun/pve-status.git
```
Link status.sh to e.g.:
```
	ln -s /path/to/pve-status/status.sh /usr/sbin/st
```
## Example
```
  ============================================================
                          SYSTEM INFO
  ============================================================
  System:        Debian GNU/Linux 11 (bullseye)
  Kernel:        5.13.19-6-pve
  Uptime:        up 1 week, 1 hour, 55 minutes
  CPU:           Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.40GHz
  
  ## CPU Temperature ##
  
  Package id 0:  +34.0°C  	Package id 1:  +32.0°C  
  Core 0:        +27.0°C  	Core 0:        +26.0°C  
  Core 1:        +25.0°C  	Core 1:        +26.0°C  
  Core 2:        +26.0°C  	Core 2:        +24.0°C  
  Core 3:        +25.0°C  	Core 3:        +24.0°C  
  Core 4:        +24.0°C  	Core 4:        +24.0°C  
  Core 5:        +27.0°C  	Core 5:        +24.0°C  
  
  ## Memory usage ##
  
  Total:         62Gi    Used:          31Gi
  Free:          30Gi    Shared:        56Mi
  
  ============================================================
                           ZFS STATUS
  ============================================================
  ## Pool status ##
   
  all pools are healthy
  
  ## Snapshots ##
  
  Last zfs snapshots
  HOURLY:     22/04/14 06:00:43 
  DAILY:      22/04/14 06:00:43 
  MONTHLY:   
  YEARLY:    

  Total Snapshots: 120

  ## Pool Capacity's  ##

  hddpool	8%
  rpool	5%
```
