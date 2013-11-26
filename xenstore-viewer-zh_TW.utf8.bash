#!/bin/bash
### Name: Simple XenStore Viewer
### Version: 1.2
### Release Date: 2012-08-17

function xenstoregetstatestr () {
	case "$1" in
		1)
			echo "正在初始化"
			;;
		2)
			echo "等待初始化"
			;;
		3)
			echo "已初始化"
			;;
		4)
			echo "已連接"
			;;
		5)
			echo "正在關閉"
			;;
		6)
			echo "已關閉"
			;;
		*)
			echo "不明"
			;;
	esac
}

function xenstoregetinfo () {
	case "$1" in
		m|h|'?'|'')
			echo " b 區塊裝置"
			echo " c 主控台"
			echo " n 網路介面卡"
			echo " p 虛擬 CPU"
			echo " r 記憶體"
			;;
		b)
			vbdpath="$xenstorepath/device/vbd"
			for i in `xenstore-list $vbdpath`
			do
				echo "虛擬裝置名稱：    $i"
				echo "虛擬裝置類型：    `xenstore-read $vbdpath/$i/device-type`"
				echo "虛擬裝置狀態：    `xenstoregetstatestr $(xenstore-read $vbdpath/$i/state)`"
				vbdbackpath="`xenstore-read $vbdpath/$i/backend`"
				echo "虛擬裝置後端名稱：`xenstore-read $vbdbackpath/dev`"
				echo "虛擬裝置後端類型：`xenstore-read $vbdbackpath/type`"
				echo "虛擬裝置後端參數：`xenstore-read $vbdbackpath/params`"
				echo -n "其他資訊：        "
				case "`xenstore-read $vbdbackpath/online`" in
					0)
						echo -n "離線"
						;;
					1)
						echo -n "線上"
						;;
					*)
						echo -n "不明"
						;;
				esac
				case "`xenstore-read $vbdbackpath/removable`" in
					0)
						echo -n "、不可卸除"
						;;
					1)
						echo -n "、卸除式裝置"
						;;
					*)
						echo -n "、不明"
						;;
				esac
				case "`xenstore-read $vbdbackpath/bootable`" in
					0)
						echo "、不可開機"
						;;
					1)
						echo "、可開機"
						;;
					*)
						echo "、不明"
						;;
				esac
				echo ""
			done
			;;
		c)
			conpath="$xenstorepath/console"
			echo "Xen Console 後端 TTY：      `xenstore-read $conpath/tty`"
			echo "Xen Console 緩衝區大小限制：`xenstore-read $conpath/limit`"
			echo "VNC 伺服器接聽於：          `xenstore-read $conpath/vnc-listen`:`xenstore-read $conpath/vnc-port`"
			echo ""
			;;
		n)
			vifpath="$xenstorepath/device/vif"
			for i in `xenstore-list $vifpath`
			do
				echo "虛擬裝置名稱：           $i"
				echo "虛擬裝置狀態：           `xenstoregetstatestr $(xenstore-read $vifpath/$i/state)`"
				echo "虛擬網路介面卡 MAC 位址：`xenstore-read $vifpath/$i/mac`"
				vifbackpath="`xenstore-read $vifpath/$i/backend`"
				echo "橋接至：                 `xenstore-read $vifbackpath/bridge`"
				echo "用來啟動/停止的 script： `xenstore-read $vifbackpath/script`"
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
			echo "記憶體大小    ：`xenstore-read $mempath/target`"
			echo "記憶體大小上限：`xenstore-read $mempath/static-max`"
			echo "視訊記憶體大小：`xenstore-read $mempath/videoram`"
			;;
		*)
			echo "不明的指令。請輸入 m 來查看說明。"
			echo "若要離開，請送出 EOF，通常按下 Control-D 即可。"
			;;
	esac
}

[ "`id -u`" != "0" ] && echo "這個 script 必須以 root 身份執行" && exit 40

if [ -z "$1" ]
then
	read -p "請輸入 domain ID 或 domain 名稱：" xendominput
else
	xendominput="$1"
fi

[ -z "$xendominput" ] && echo "使用預設值 doamin 0" && xendominput=0

echo "正在搜尋 domain $xendominput ......"

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
	echo "找不到 domain $xendominput" && exit 42
else
	echo "XenStore 路徑是 $xenstorepath"
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
