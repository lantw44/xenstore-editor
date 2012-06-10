#!/bin/bash
### Name: Simple XenStore Editor
### Version: 1.1
### Release Date: 2012-06-11

[ "`id -u`" != "0" ] && echo "This script should be run as root." && exit 40

if [ "$1" ];then
	current="$1"
else
	current="/"
fi

should_exit=0
first_run=1
setdefault=0
prevdir="$current"
tmpfile=`mktemp`
scripttitle="               Simple XenStore Editor Version 1.1              "
scriptshorttitle="Simple XenStore Editor"

function getxenfullpath () {
	if [ "$1" = "/" ]
	then
		echo "/$2"
	else
		echo "$1/$2"
	fi
}

function getusernewvalue () {
	local initvalue="$3"
	while true
	do
		dialog --ascii-lines --title "$1" --extra-button --extra-label "File Browser" --inputbox "$2" 0 0 "$initvalue" 2> "$tmpfile"
		local exitstat=$?
		case "$exitstat" in 
			0|1)
				return "$exitstat"
				;;
			3)
				local initdir="/"
				local tmpfile2="`mktemp`"
				local selectedfile="/"
				local nowvalue="`cat "$tmpfile"`"
				local parentdir="`dirname "$nowvalue"`"
				if [ "`echo "$nowvalue" | cut -c 1`" != "/" ] || [ '!' -e "$parentdir" ] 
				then
					dialog --ascii-lines --title "File Browser" --msgbox "$parentdir directory does not exits" 0 0
					initdir="`pwd`/"
				else
					initdir="$nowvalue"
				fi
				dialog --ascii-lines --title "Use space-bar to copy the current selection" --fselect "$initdir" 13 75 2> "$tmpfile2"
				if [ "$?" = "0" ]
				then
					selectedfile="`cat "$tmpfile2"`"
					initvalue="$selectedfile"
				else
					initvalue="$nowvalue"
				fi
				rm -f "$tmpfile2"
				;;
		esac
	done
}

while [ "$should_exit" = "0" ]
do
	unset dirlist
	unset valuelist
	unset i
	unset j
	xenstore-list "$current" > "$tmpfile"
	if [ "$?" != "0" ]; then
		dialog --ascii-lines --title "$scripttitle" --msgbox "Cannot list the directory $current" 0 0
		if [ "$first_run" != "0" ]
		then
			exit 1
		else
			current="$prevdir"
			continue
		fi
	fi
	first_run=0
	declare -a dirlist
	declare -a valuelist
	mapfile -t dirlist < "$tmpfile"
	declare -i i=0
	declare -i j=0
	if [ -z "${dirlist[0]}" ]
	then
		valuelist[0]="(Empty)"
		valuelist[1]=""
	else
		while [ "${dirlist[$i]}" ]
		do
			valuelist[$j]="${dirlist[$i]}"
			j=$j+1
			valuelist[$j]="`xenstore-read $current/${dirlist[$i]}`"
			j=$j+1
			i=$i+1
		done
	fi
	if [ "$setdefault" = "0" ]
	then
		dialog --ascii-lines --title "$scripttitle" --ok-label "Chdir" --cancel-label "Exit" --extra-button --extra-label "Edit" --menu "$current" 0 0 0 "${valuelist[@]}" 2> "$tmpfile"
	else
		dialog --ascii-lines --title "$scripttitle" --ok-label "Chdir" --cancel-label "Exit" --extra-button --extra-label "Edit" --default-item "$setdefaultvalue" --menu "$current" 0 0 0 "${valuelist[@]}" 2> "$tmpfile"
	fi
	dialogexit=$?
	dialogout="`cat "$tmpfile"`"
	setdefault=0
	case "$dialogexit" in
		0)
			unset valuepathvalid
			descending="`getxenfullpath "$current" "$dialogout"`"
			ascending="`dirname "$current"`"
			usevalue="`xenstore-read "$descending"`"
			if [ "$usevalue" ]; then
				xenstore-read "$usevalue" 2> /dev/null
				[ "$?" = "0" ] && valuepathvalid=1
			fi
			if [ "$dialogout" = "(Empty)" ]; then
				dialog --ascii-lines --title "$scriptshorttitle - Chdir" --menu "Choose from the list" 0 0 0 "Back" "Go to $ascending" "Manual" "Type a XenStore Path" 2> "$tmpfile"
				dialogexit=$?
			elif [ "$usevalue" ] &&  [ "$valuepathvalid" = "1" ]; then
				dialog --ascii-lines --title "$scriptshorttitle - Chdir" --menu "Choose from the list" 0 0 0 "Enter" "Go to $descending" "Back" "Go to $ascending" "UseValue" "Go to $usevalue" "Manual" "Type a XenStore Path" 2> "$tmpfile"
				dialogexit=$?
			else
				dialog --ascii-lines --title "$scriptshorttitle - Chdir" --menu "Choose from the list" 0 0 0 "Enter" "Go to $descending" "Back" "Go to $ascending" "Manual" "Type a XenStore Path" 2> "$tmpfile"
				dialogexit=$?
			fi
			if [ "$dialogexit" = "0" ]
			then
				dialogout2="`cat "$tmpfile"`"
				case "$dialogout2" in
					"Enter")
						prevdir="$current"
						current="$descending"
						;;
					"Back")
						prevdir="$current"
						current="$ascending"
						;;
					"UseValue")
						prevdir="$current"
						current="$usevalue"
						;;
					"Manual")
						dialog --ascii-lines --title "$scriptshorttitle - Chdir - Manual" --inputbox "XenStore Directory Name" 0 0 "$current" 2> "$tmpfile"
						if [ "$?" = "0" ]
						then
							prevdir="$current"
							current="`cat "$tmpfile"`"
						else 
							setdefault=1
							setdefaultvalue="$dialogout"
						fi
						;;
				esac
			else
				setdefault=1
				setdefaultvalue="$dialogout"
			fi
			;;
		1)
			if dialog --ascii-lines --title "$scriptshorttitle - Exit" --yesno "Do you really want to quit?" 0 0
			then
				should_exit=1
			fi
			;;
		3)
			if [ "$dialogout" = "(Empty)" ]
			then
				dialog --ascii-lines --title "$scriptshorttitle - Edit" --menu "Choose from the list" 0 0 0 "Add" "Add a new value" 2> "$tmpfile"
				dialogexit=$?
				dialogout2="`cat "$tmpfile"`"
			else
				dialog --ascii-lines --title "$scriptshorttitle - Edit" --menu "Choose from the list" 0 0 0 "Modify" "Modify this value" "Remove" "Remove this value" "Add" "Add a new value" 2> "$tmpfile"
				dialogexit=$?
				dialogout2="`cat "$tmpfile"`"
			fi
			if [ "$dialogexit" = "0" ]
			then
				case "$dialogout2" in 
					"Add")
						dialog --ascii-lines --title "$scriptshorttitle - Edit - Add" --inputbox "Name" 0 0 2> "$tmpfile"
						if [ "$?" = "0" ]
						then
							newname="`cat "$tmpfile"`"
						else
							setdefault=1
							setdefaultvalue="$dialogout"
							continue
						fi
						getusernewvalue "$scriptshorttitle - Edit - Add" "Value" ""
						if [ "$?" = "0" ]
						then
							newvalue="`cat "$tmpfile"`"
						else
							setdefault=1
							setdefaultvalue="$dialogout"
							continue
						fi
						fullpath="`getxenfullpath "$current" "$newname"`"
						outmsg="`xenstore-write "$fullpath" "$newvalue" 2>&1`"
						if [ "$?" != "0" ]
						then
							dialog --ascii-lines --title "$scriptshorttitle - Edit - Add" --msgbox "$outmsg" 0 0
						else
							setdefault=1
							setdefaultvalue="$dialogout"
						fi
					;;
					"Modify")
						fullpath="`getxenfullpath "$current" "$dialogout"`"						
						getusernewvalue "$scriptshorttitle - Edit - Modify" "New value" "`xenstore-read "$fullpath"`"
						if [ "$?" = "0" ]
						then
							dialogout3="`cat "$tmpfile"`"
							outmsg="`xenstore-write "$fullpath" "$dialogout3" 2>&1`"
							if [ "$?" != "0" ]
							then
								dialog --ascii-lines --title "$scriptshorttitle - Edit - Modify" --msgbox "$outmsg" 0 0
							else
								setdefault=1
								setdefaultvalue="$dialogout"
							fi
						else
							setdefault=1
							setdefaultvalue="$dialogout"
						fi
					;;
					"Remove")
						fullpath="`getxenfullpath "$current" "$dialogout"`"
						if dialog --ascii-lines --title "$scriptshorttitle - Edit - Remove" --yesno "Do you really want to delete the value $dialogout?" 0 0 
						then
							outmsg="`xenstore-rm "$fullpath" 2>&1`"
							if [ "$?" != "0" ]
							then
								dialog --ascii-lines --title "$scriptshorttitle - Edit - Remove" --msgbox "$outmsg" 0 0
							else
								setdefault=1
								setdefaultvalue="$dialogout"
							fi
						else
							setdefault=1
							setdefaultvalue="$dialogout"
						fi
					;;
				esac
			else
				setdefault=1
				setdefaultvalue="$dialogout"
			fi
			;;
	esac
done

rm -f "$tmpfile"
