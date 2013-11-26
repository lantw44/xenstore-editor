
Simple bash scripts to get and modify information in XenStore

Runtime requirement：

	1. GNU bash
	2. cdialog (http://invisible-island.net/dialog/dialog.html)
	3. xenstore-{list,read,write,rm} executables
	4. If it is run in Xen Dom0, xenstored must be started.
	5. If it is run in Xen DomU, some filesystem should be mounted for
	   xenstore-* tools to work.

Known problems:

 	1. This tool may crash FreeBSD paravirtualized domU.
	2. xenstore-editor does not work with NetBSD mktemp.
	3. xenstore-editor may file to start in Xen DomU when starting without
	   arguments. Workaround: use this command to start xenstore-editor:
	   xenstore-editor.sh /local/domain/`xenstore-read domid`
