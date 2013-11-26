 -- UTF-8 --

這個小工具可以讓檢視與修改 xenstore 內的值更方便

執行環境需求：

	1. GNU bash
	2. cdialog (http://invisible-island.net/dialog/dialog.html)
	3. xenstore-{list,read,write,rm} 可執行檔
	4. 如果是在 Xen Dom0 執行，xenstored 服務必須啟動。
	5. 如果是在 Xen DomU 執行，可能需要額外掛載一些特殊的檔案系統，才能使
	   xenstore-* 正常運作。

已知問題：

	1. 這個小工具可能導致 FreeBSD 半虛擬 domU 當機。
	2. xenstore-editor 無法使用 NetBSD 的 mktemp 產生暫存檔。
	3. xenstore-editor 不加參數時無法在 domU 中執行，簡單的解決方法是改為
	   執行以下的指令：
	   xenstore-editor.sh /local/domain/`xenstore-read domid`
