#!/bin/bash
### 名稱: Simple XenStore Editor
### 版本: 1.2
### 發行日期: 2012-08-18

[ "`id -u`" != "0" ] && echo "這個 script 必須以 root 身份執行。" && exit 40

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
scripttitle="               簡易 XenStore 編輯工具 版本 1.2               "
scriptshorttitle="簡易 XenStore 編輯工具"

if [ -z "$DIALOG" ]; then
	for i in dialog cdialog
	do
		DIALOG=`which $i 2> /dev/null`
		[ "$DIALOG" ] && break
	done
fi

[ -z "$DIALOG" ] && echo "在 PATH 中找不到必要的程式 dialog (可以嘗試用環境變數 DIALOG 來指定這個可執行檔的位置)" && exit 42

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
		$DIALOG --title "$1" --extra-button --extra-label "檔案瀏覽器" --inputbox "$2" 0 0 "$initvalue" 2> "$tmpfile"
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
					$DIALOG --title "檔案瀏覽器" --msgbox "$parentdir 目錄不存在" 0 0
					initdir="`pwd`/"
				else
					initdir="$nowvalue"
				fi
				$DIALOG --title "請用空白鍵來複製游標所在位置的檔案路徑" --fselect "$initdir" 13 75 2> "$tmpfile2"
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
		$DIALOG --title "$scripttitle" --msgbox "無法從 $current 取得檔案清班" 0 0
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
		$DIALOG --title "$scripttitle" --ok-label "切換目錄" --cancel-label "離開" --extra-button --extra-label "編輯" --menu "$current" 0 0 0 "${valuelist[@]}" 2> "$tmpfile"
	else
		$DIALOG --title "$scripttitle" --ok-label "切換目錄" --cancel-label "離開" --extra-button --extra-label "編輯" --default-item "$setdefaultvalue" --menu "$current" 0 0 0 "${valuelist[@]}" 2> "$tmpfile"
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
				$DIALOG --title "$scriptshorttitle - 切換目錄" --menu "請從清單中選取" 0 0 0 "Back" "進入 $ascending" "Manual" "輸入 XenStore 路徑" 2> "$tmpfile"
				dialogexit=$?
			elif [ "$usevalue" ] &&  [ "$valuepathvalid" = "1" ]; then
				$DIALOG --title "$scriptshorttitle - 切換目錄" --menu "請從清單中選取" 0 0 0 "Enter" "進入 $descending" "Back" "進入 $ascending" "UseValue" "進入 $usevalue" "Manual" "輸入 XenStore 路徑" 2> "$tmpfile"
				dialogexit=$?
			else
				$DIALOG --title "$scriptshorttitle - 切換目錄" --menu "請從清單中選取" 0 0 0 "Enter" "進入 $descending" "Back" "進入 $ascending" "Manual" "輸入 XenStore 路徑" 2> "$tmpfile"
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
						$DIALOG --title "$scriptshorttitle - 切換目錄 - Manual" --inputbox "XenStore 目錄名稱" 0 0 "$current" 2> "$tmpfile"
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
			if $DIALOG --title "$scriptshorttitle - 離開" --yesno "你確定要離開嗎？" 0 0
			then
				should_exit=1
			fi
			;;
		3)
			if [ "$dialogout" = "(Empty)" ]
			then
				$DIALOG --title "$scriptshorttitle - 編輯" --menu "請從清單中選取" 0 0 0 "Add" "加入新值" 2> "$tmpfile"
				dialogexit=$?
				dialogout2="`cat "$tmpfile"`"
			else
				$DIALOG --title "$scriptshorttitle - 編輯" --menu "請從清單中選取" 0 0 0 "Modify" "修改此值" "Remove" "刪除此值" "Add" "加入新值" 2> "$tmpfile"
				dialogexit=$?
				dialogout2="`cat "$tmpfile"`"
			fi
			if [ "$dialogexit" = "0" ]
			then
				case "$dialogout2" in
					"Add")
						$DIALOG --title "$scriptshorttitle - 編輯 - Add" --inputbox "名稱" 0 0 2> "$tmpfile"
						if [ "$?" = "0" ]
						then
							newname="`cat "$tmpfile"`"
						else
							setdefault=1
							setdefaultvalue="$dialogout"
							continue
						fi
						getusernewvalue "$scriptshorttitle - 編輯 - Add" "值" ""
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
							$DIALOG --title "$scriptshorttitle - 編輯 - Add" --msgbox "$outmsg" 0 0
						else
							setdefault=1
							setdefaultvalue="$dialogout"
						fi
					;;
					"Modify")
						fullpath="`getxenfullpath "$current" "$dialogout"`"						
						getusernewvalue "$scriptshorttitle - 編輯 - Modify" "值" "`xenstore-read "$fullpath"`"
						if [ "$?" = "0" ]
						then
							dialogout3="`cat "$tmpfile"`"
							outmsg="`xenstore-write "$fullpath" "$dialogout3" 2>&1`"
							if [ "$?" != "0" ]
							then
								$DIALOG --title "$scriptshorttitle - 編輯 - Modify" --msgbox "$outmsg" 0 0
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
						if $DIALOG --title "$scriptshorttitle - 編輯 - Remove" --yesno "你確定要刪除 $dialogout 嗎？" 0 0
						then
							outmsg="`xenstore-rm "$fullpath" 2>&1`"
							if [ "$?" != "0" ]
							then
								$DIALOG --title "$scriptshorttitle - 編輯 - Remove" --msgbox "$outmsg" 0 0
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
