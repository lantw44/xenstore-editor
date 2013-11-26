#!/bin/bash
### Name: Simple XenStore Viewer
### Version: 1.2
### Release Date: 2012-08-17

function xenstoregetstatestr () {
	case "$1" in
		1)
			echo "Initializing"
			;;
		2)
			echo "Waiting for initializing"
			;;
		3)
			echo "Initialized"
			;;
		4)
			echo "Connected"
			;;
		5)
			echo "Closing"
			;;
		6)
			echo "Closed"
			;;
		*)
			echo "Unknown"
			;;
	esac
}

function xenstoregetinfo () {
	case "$1" in
		m|h|'?'|'')
			echo " b Block device"
			echo " c Console"
			echo " n Network"
			echo " p Virtual CPUs"
			echo " r Memory"
			;;
		b)
			vbdpath="$xenstorepath/device/vbd"
			for i in `xenstore-list $vbdpath`
			do
				echo "Virtual Device Name:              $i"
				echo "Virtual Device Type:              `xenstore-read $vbdpath/$i/device-type`"
				echo "Virtual Device State:             `xenstoregetstatestr $(xenstore-read $vbdpath/$i/state)`"
				vbdbackpath="`xenstore-read $vbdpath/$i/backend`"
				echo "Virtual Device Backend Name:      `xenstore-read $vbdbackpath/dev`"
				echo "Virtual Device Backend Type:      `xenstore-read $vbdbackpath/type`"
				echo "Virtual Device Backend Parameter: `xenstore-read $vbdbackpath/params`"
				echo -n "Other Information:                "
				case "`xenstore-read $vbdbackpath/online`" in
					0)
						echo -n "Offline"
						;;
					1)
						echo -n "Online"
						;;
					*)
						echo -n "Unknown"
						;;
				esac
				case "`xenstore-read $vbdbackpath/removable`" in
					0)
						echo -n ", Non-removable"
						;;
					1)
						echo -n ", Removable"
						;;
					*)
						echo -n ", Unknown"
						;;
				esac
				case "`xenstore-read $vbdbackpath/bootable`" in
					0)
						echo ", Non-bootable"
						;;
					1)
						echo ", Bootable"
						;;
					*)
						echo ", Unknown"
						;;
				esac
				echo ""
			done
			;;
		c)
			conpath="$xenstorepath/console"
			echo "Xen Console Backend TTY:       `xenstore-read $conpath/tty`"
			echo "Xen Console Buffer Size Limit: `xenstore-read $conpath/limit`"
			echo "VNC Server Listen on:          `xenstore-read $conpath/vnc-listen`:`xenstore-read $conpath/vnc-port`"
			echo ""
			;;
		n)
			vifpath="$xenstorepath/device/vif"
			for i in `xenstore-list $vifpath`
			do
				echo "Virtual Device Name:           $i"
				echo "Virtual Device State:          `xenstoregetstatestr $(xenstore-read $vifpath/$i/state)`"
				echo "Virtual Interface MAC Address: `xenstore-read $vifpath/$i/mac`"
				vifbackpath="`xenstore-read $vifpath/$i/backend`"
				echo "Bridge to:                     `xenstore-read $vifbackpath/bridge`"
				echo "Script used to create/stop:    `xenstore-read $vifbackpath/script`"
				echo ""
			done
			;;
		p)
			cpupath="$xenstorepath/cpu"
			for i in `xenstore-list $cpupath`
			do
				echo "CPU $i: `xenstore-read $cpupath/$i/availability`"
			done
			;;
		r)
			mempath="$xenstorepath/memory"
			echo "Memory Size:         `xenstore-read $mempath/target`"
			echo "Maximum Memory Size: `xenstore-read $mempath/static-max`"
			echo "Video Memory Size:   `xenstore-read $mempath/videoram`"
			;;
		*)
			echo "Unrecognized command. Type m for help."
			echo "Use EOF (typically Control-D) to quit this script."
			;;
	esac
}

[ "`id -u`" != "0" ] && echo "This script should be run as root." && exit 40

if [ -z "$1" ]
then
	read -p "Type a domain ID or domain name: " xendominput
else
	xendominput="$1"
fi

[ -z "$xendominput" ] && echo "Using default doamin 0" && xendominput=0

echo "Searching for domain $xendominput ..."

if xenstore-read /local/domain/$xendominput 1> /dev/null 2> /dev/null
then
	xenstorepath="/local/domain/$xendominput"
else
	for i in `xenstore-list /local/domain`
	do
		if [ "$xendominput" = "`xenstore-read /local/domain/$i/name 2> /dev/null`" ]
		then
			xenstorepath="/local/domain/$i"
			break
		fi
	done
fi

if [ -z "$xenstorepath" ]
then
	echo "Domain $xendominput not found." && exit 42
else
	echo "XenStore Path is $xenstorepath"
fi

if [ -z "$2" ]
then
	while read -p "XSView>>> " infocmdinput
	do
		xenstoregetinfo "$infocmdinput"
	done
else
	xenstoregetinfo "$2"
fi
