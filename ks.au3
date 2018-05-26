#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\Autoit\Icons\rh.ico
#AutoIt3Wrapper_Outfile_x64=..\ks.exe
#AutoIt3Wrapper_Res_Fileversion=1.0.0.8
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Field=ProductName|Kickstart generator
#AutoIt3Wrapper_Res_Description=Glorified DHCP
#AutoIt3Wrapper_Res_LegalCopyright=pana ti se face rau
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Run_Debug_Mode=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <InetConstants.au3>
#include <WinAPIFiles.au3>
#include <INet.au3> ; needed for get source (hmtl)
#include <String.au3> ; needed for StringBetween
#include <MsgBoxConstants.au3> ; needed for MsgBox
#include <File.au3> ; needed for _FileWriteFromArray
#include <Array.au3>
#include <Excel.au3>
#include <MsgBoxConstants.au3>
#include <Debug.au3>

_DebugSetup("dc pwla mea nu merge?", True) ; start displaying debug environment

Opt("WinTextMatchMode", 2) ;1=complete, 2=quick
Opt("MouseCoordMode", 2)
Opt("TrayIconDebug", 1)
FileInstall("7z.exe", @TempDir & "\7z.exe", 1)
FileInstall("plink.exe", @TempDir & "\plink.exe", 1)
FileInstall("mkisofs.exe", @TempDir & "\mkisofs.exe", 1)
FileInstall("cygwin1.dll", @TempDir & "\cygwin1.dll", 1)
FileInstall("postreboot.sh", @TempDir & "\postreboot.sh", 1)
FileInstall("Load_ILO_ISO.ksh", @ScriptDir & "\Load_ILO_ISO.ksh", 1)
FileInstall("isoserve", @ScriptDir & "\isoserve", 1)
FileInstall("WinSCP.com", @ScriptDir & "\WinSCP.com", 1)
FileInstall("WinSCP.exe", @ScriptDir & "\WinSCP.exe", 1)
FileInstall("DC.csv", @ScriptDir & "\DC.csv", 1)
FileInstall("tcpdump", @ScriptDir & "\tcpdump", 1)
FileInstall("libpcap.so.1", @ScriptDir & "\libpcap.so.1", 1)

HotKeySet("{ESC}", "_Exit") ;If you press ESC the script will stop
HotKeySet("{F12}", "hais")

Global $DCfile = @ScriptDir & "\DC.csv"
Global $iso = "ECORP_RHEL7.2_x86_64-v002.iso"
Global $isolinux = @TempDir & "\isolinux.cfg"
Global $ks = @TempDir & "\ks.cfg"
Global $postreboot = @TempDir & "\postreboot.sh"
Global $fcsv = @ScriptDir & "\network.csv"
Global $aTmp, $cOUT, $domain, $url, $domain, $timezone, $ns, $ns1, $ns2, $ping, $pingreport, $enaf
Global $mgmtlist = @ScriptDir & "/mgmt-list"
Global $urlUUID = "http://ecorp.domain.com/wshsrvops/Vm-HealthVmId.cfm?Filter_VmType=Server&VmName="
Dim $ipxy, $maskxy, $gwxy, $hostnamexy, $ns, $ns1, $ns2, $timezone, $system, $aDC, $cPID, $cOUT
Global $user = @UserName
Global $pass = "Intranet3"
Global $vmtxt = @ScriptDir & '\vm.txt'
Global $searchH = "[REGEXPCLASS:WindowsForms10.SysListView32.app.0.*; INSTANCE:1]" ;<---CHANGE THIS B4 RUN
;Global $mount = "MISO";<---CHANGE THIS B4 RUN
;Global $mount = "DSISO";<---CHANGE THIS B4 RUN
Global $mount = "LISO" ;<---CHANGE THIS B4 RUN
; Create application object and open an example workbook
Local $aVMtxt = FileReadToArray($vmtxt)
If FileExists($vmtxt) Then FileRecycle($vmtxt)
_DebugOut("Started @ " & @HOUR & ":" & @MIN & " ")

Global $victim = "jumpbox.domain.com"

If Not _FileReadToArray($DCfile, $aDC, 4, ",") Then
	MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the DC file. @error: " & @error) ; An error occurred reading the DC file.
EndIf

; Create application object and open an example workbook
Global $aTmp[0][9]
Local Const $sMessage = "Select Network Design"
Local $oExcel = _Excel_Open() ;(False)

Local $sFileOpenDialog = FileOpenDialog("Open file", "C:\Work\VPMO\" & "\", "Network Design (*.xls;*.xlsx)", 1)
;~ Local $sFileOpenDialog = "C:\Work\VPMO\141495\KC_141495_3Q17-LR-ITL.xlsx"
If @error Then
	; Display the error message.
	MsgBox($MB_SYSTEMMODAL, "", "No file(s) were selected.")
	Exit
EndIf

;Local $file = @ScriptDir & "\VPMO 140857 FRFDCA60.xls"
If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel import", "Error opening " & $sFileOpenDialog & @CRLF & "@error = " & @error & ", @extended = " & @extended)

Local $oWorkbook = _Excel_BookOpen($oExcel, $sFileOpenDialog)
If @error Then
	MsgBox($MB_SYSTEMMODAL, "Excel import", "Error opening " & $sFileOpenDialog & @CRLF & "@error = " & @error & ", @extended = " & @extended)
	_Excel_Close($oExcel)
	Exit
EndIf

Local $aXls = _Excel_RangeRead($oWorkbook, Default, Default, Default, True)
If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel import", "Error reading " & $sFileOpenDialog & @CRLF & "@error = " & @error & ", @extended = " & @extended)
_Excel_Close($oExcel)

Dim $hostname = _ArraySearch($aXls, "hostname", 0, 0, 0, 1), $hostnameH = "hostname"

If $hostname = -1 Then
	Dim $hostname = _ArraySearch($aXls, "FQDN", 0, 0, 0, 1), $hostnameH = "FQDN"
EndIf

For $i = 0 To $hostname - 1
	_ArrayDelete($aXls, 0)
Next

Dim $prev, $domain
Global $hostname_row = _ArraySearch($aXls, $hostnameH, 0, 0, 0, 1, 1, -1, False)
Global $hostname_col = _ArraySearch($aXls, $hostnameH, 0, 0, 0, 1, 1, -1, True)

Global $ipH = "IP Address"
Global $ip_col = _ArraySearch($aXls, $ipH, 0, 0, 0, 1, 1, -1, True)

Global $mask = _ArraySearch($aXls, "Subnet Mask", 0, 0, 0, 1), $maskH = "Subnet Mask"
If $mask = -1 Then
	Global $mask = _ArraySearch($aXls, "Subnet Netmask", 0, 0, 0, 1), $maskH = "Subnet Netmask"
EndIf
If $mask = -1 Then
	Global $mask = _ArraySearch($aXls, "mask", 0, 0, 0, 1), $maskH = "mask"
EndIf
If $mask = -1 Then
	Global $mask = _ArraySearch($aXls, "subnet", 0, 0, 0, 1), $maskH = "subnet"
EndIf

Global $mask_col = _ArraySearch($aXls, $maskH, 0, 0, 0, 1, 1, -1, True)

Global $gw = _ArraySearch($aXls, "Gateway", 0, 0, 0, 1), $gwH = "Gateway"
If $gw = -1 Then
	Global $gw = _ArraySearch($aXls, "Default Gateway", 0, 0, 0, 1), $gwH = "Default Gateway"
EndIf
Global $gw_col = _ArraySearch($aXls, $gwH, 0, 0, 0, 1, 1, -1, True)
_DebugOut("Hostname @ Col " & $hostname_col)
_DebugOut("IP @ Col " & $ip_col)
_DebugOut("Mask @ Col " & $mask_col)
_DebugOut("Gateway @ Col " & $gw_col)
If _DebugOut("Display BC Array") Then _ArrayDisplay($aXls, "Initial")

TCPStartup()
Local $prev[UBound($aXls, 1)]
For $i = 1 To (UBound($aXls, 1) - 1)

	$aXls[$i][$hostname_col] = StringReplace($aXls[$i][$hostname_col], "-prod", "") ; cuz ppl are stupid

	$meh = StringStripWS(StringLower($aXls[$i][$hostname_col]), 8)

	If (StringLen($meh) > 8 And StringInStr($meh, ".") = 0) Or $meh = "" Or StringInStr($meh, "-") Or StringInStr($meh, "nas") Or StringInStr($meh, "ebr") Or StringInStr($meh, "enaf") Or StringInStr($meh, "mgmt") <> 0 Then
		ContinueLoop
	EndIf

	If _ArraySearch($prev, $meh, 0, 0, 0, 1) <> -1 Then
		_DebugOut("duplicate" & '"' & $meh & '"' & @CR)
		ContinueLoop
	EndIf
	$prev[$i] = $meh

	_DebugReportVar("Hostname AD", $meh)

	If StringInStr($meh, ".") Then
		DC_guess($meh)
		_DebugOut("DOMAIN" & '"' & $meh & '"' & @CR)
		$ip = TCPNameToIP($meh)
		If $ip <> "" Then
			_DebugOut("IP" & $ip & '"' & $meh & '"' & @CR)
			Guess_net_info($ip)
		Else
			MsgBox(0, "DUDE", "WTF? nslookup failed for FQDN " & $meh)
		EndIf
	Else
		DC_guess($meh)
		_DebugOut(@CRLF & $meh & "." & $domain)
		$ip = TCPNameToIP($meh & "." & $domain)
		If $ip <> "" Then
			_DebugOut("IP" & $ip & '"' & $meh & '"' & @CR)
			Guess_net_info($ip)
		Else
			MsgBox(0, "DUDEE", "WTF? nslookup failed for hostname: " & $meh & " domain: " & $domain)
		EndIf
	EndIf
Next
TCPShutdown()

_ArrayColInsert($aTmp, 0)

If UBound($aTmp) < 1 Then
	_ArrayDisplay($aTmp)
	MsgBox(0, "Something Happened", "Couldn't find a useful hostname in network design")
	Exit
EndIf
_DebugOut("<<DC Info>>")
_DebugOut("URL: " & $url)
_DebugOut("Domain: " & $enaf & $domain)
_DebugOut("TZ: " & $timezone)
_DebugOut("NS: " & $ns)
_DebugOut("NS1: " & $ns1)
_DebugOut("NS2: " & $ns2)

If _DebugOut("Working Array") Then _ArrayDisplay($aTmp, "Working Array")

$type = StringMid($aTmp[0][4], 4, 1)
Select
;~~~~~HP~~~~~
	Case $type = "h"
		Global $system = "HW"
		_DebugOut("I haz HP" & @CRLF)
		Global $type = "HP"
		FileInstall("hpssacli", @TempDir & "\hpssacli", 1)
		FileInstall("HPRaid.sh", @TempDir & "\HPRaid.sh", 1)
;~~~~~Dell~~~~~
	Case $type = "d"
		Global $system = "HW"
		_DebugOut("I haz Dell" & @CRLF)
		Global $type = "Dell"
;~~~~~Hitachi~~~~~
	Case $type = "o"
		Global $system = "HW"
		_DebugOut("I haz Hitachi" & @CRLF)
		Global $type = "Hitachi"
;~~~~~VMware~~~~~
	Case $type = "v"
		Global $system = "VM"
		_DebugOut("I haz VMware" & @CRLF)
		For $i = 0 To UBound($aTmp) - 1
			$UUID = Get_UUID($aTmp[$i][4])
			$aTmp[$i][0] = $UUID
		Next

	Case Else ; If nothing matches then execute the following.
		MsgBox($MB_SYSTEMMODAL, "THIS", "WTF is this " & $aTmp[0][4])
		Exit
EndSelect

If $system = "HW" Then
;~ ping testing
	For $i = 0 To UBound($aTmp) - 1
		If StringInStr($domain, "enaf.") Then
			Global $mgmtdomain = StringReplace($domain, "enaf.", "-mgmt.")
		Else
			Global $mgmtdomain = "-mgmt." & $domain
		EndIf
		$ping = Ping($aTmp[$i][4] & $mgmtdomain, 1550)
		If @error Or $ping = 0 Then
			$pingreport &= $aTmp[$i][4] & $mgmtdomain & @LF
		EndIf

		_DebugOut("Ping " & $aTmp[$i][4] & $mgmtdomain & ", Reply " & $ping & @CRLF)

		$test = Ping($aTmp[$i][4] & "." & $domain, 1550)
		If $test > 0 Then
			MsgBox(0, "carefull now", $aTmp[$i][4] & "." & $domain & " maybe it's already installed???")
		EndIf

	Next

	If $pingreport <> "" Then
		MsgBox(0, "ping report", "The following mgmt console(s) are not accessible:" & @LF & $pingreport & @LF & "Fix it and re-run this script")
;~ 			Exit
	EndIf

	_DebugOut("Scraping for serial number" & @CRLF)
	For $i = 0 To UBound($aTmp) - 1
		_DebugOut(@CRLF & ($i + 1) & ")." & $aTmp[$i][4])
		$PID = Get_SN($aTmp[$i][4])

		If $PID Then
			$aTmp[$i][0] = $cOUT
		EndIf

		If $aTmp[$i][0] = "" Or $PID = False Then
			$error = MsgBox(2, "Error", "Could not get serial number for " & $aTmp[$i][4] & @CRLF & "Output: " & $cOUT & @CRLF & "PID: " & $PID)
			If $error = 3 Then Exit
			If $error = 4 Then ; RETRY
				$ping = 10000
				$PID = Get_SN($aTmp[$i][4])

				If $cOUT <> "" Then
					_DebugOut($cOUT & @CRLF)
					$aTmp[$i][0] = $cOUT
				EndIf
				If $aTmp[$i][0] = "" Or $PID = False Then
					$error = MsgBox(1, "Error", "Nope that didn't work" & @CRLF & "Should we ignore it?" & @CRLF)
				EndIf
				If $error = 2 Then Exit
				If $error = 1 Then ; IGNORE
					$aTmp[$i][0] = "OFFLINE"
					_DebugOut("OFFLINE" & @CRLF)
				EndIf
			EndIf
			If $error = 5 Then ; IGNORE
				$aTmp[$i][0] = "OFFLINE"
				_DebugOut("OFFLINE" & @CRLF)
			EndIf

		EndIf
	Next
EndIf
_ArrayDisplay($aTmp, "getting ready for ks")

_FileWriteFromArray($fcsv, $aTmp, 0, Default, ",")

If $system = "HW" Then

	If FileExists($mgmtlist) Then FileRecycle($mgmtlist)
	$hFileOpen = FileOpen($mgmtlist, $FO_APPEND)
	If $hFileOpen = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the mgmt list.")
		Exit
	EndIf
	For $i = 0 To (UBound($aTmp, 1) - 1)
		FileWrite($hFileOpen, $aTmp[$i][4] & "-mgmt." & $domain & @LF)
	Next
	FileClose($hFileOpen)

EndIf

;If @error Then MsgBox(0, "error", @error)
;~~~~~~~~~~Kickstart~~~~~~~~;

Local $mail = $user & "@ECORP.com"

If FileExists(@ScriptDir & "\" & $iso) And FileGetSize(@ScriptDir & "\" & $iso) > 460000000 Then
	RunWait(@TempDir & "\7z.exe x -y -o" & @TempDir & "\extract\ " & @ScriptDir & "\" & $iso)
	If @error Then
		MsgBox(4096, "7z", "Extracting ISO failed! Error code: " & @error)
		Exit
	EndIf

Else
	ProgressOn("Downloading... | Press <ESC> to abort", $iso, "0%", @DesktopWidth / 2, @DesktopHeight / 2, 18)
	$iso_url = "http://thingz.mt.ECORP.com/images/" & $iso ;Set URL
	$folder = @ScriptDir & "\" & $iso ;Set folder
	$hInet = InetGet($iso_url, $folder, 1, 1) ;Forces a reload from the remote site and return immediately and download in the background
	$FileSize = InetGetSize($iso_url) ;Get file size
	While Not InetGetInfo($hInet, 2) ;Loop until download is finished
		Sleep(500) ;Sleep for half a second to avoid flicker in the progress bar
		$BytesReceived = InetGetInfo($hInet, 0) ;Get bytes received
		$Pct = Int($BytesReceived / $FileSize * 100) ;Calculate percentage
		ProgressSet($Pct, $Pct & "%") ;Set progress bar
	WEnd
	ProgressOff()
EndIf

Local $1st = "#!/bin/sh" & @LF & _
		"# copy network info to /tmp" & @LF & _
		"cp /mnt/install/repo/isolinux/tcpdump /tmp/tcpdump" & @LF & _
		"cp /mnt/install/repo/isolinux/libpcap.so.1 /tmp/libpcap.so.1" & @LF & _
		"export LD_LIBRARY_PATH=/tmp" & @LF & _
		"echo 'tcpdump:x:72:72::/:/sbin/nologin' >> /etc/passwd" & @LF & _
		"cp /mnt/install/repo/isolinux/network.csv /tmp/network.csv" & @LF & _
		"cp /mnt/install/repo/isolinux/postreboot.sh /tmp/postreboot.sh" & @LF & _
		"# get current serial number from dmidecode" & @LF & _
		"serial=$(/usr/sbin/dmidecode -t 1 | grep 'Serial Number' | awk '{print $3}')" & @LF & _
		"if [[ $serial =~ VMware.* ]]; then serial=$(/usr/sbin/dmidecode -s system-uuid); eth=$(for i in $(ifconfig|grep -v lo|grep -i ': '|cut -d: -f1); do echo -n $i;ethtool $i|grep -i speed;done|awk '/10000Mb/ {print $1}'|head -1); else eth=$(for i in $(ifconfig|grep -v lo|grep -i ': '|cut -d: -f1); do echo -n $i;ethtool $i|grep -i speed;done|awk '/1000Mb/ {print $1}'|head -1); fi" & @LF & _
		"if [[ $(/usr/sbin/dmidecode -t 1 | grep HP | awk '{print $2}') = HP ]] ; then" & @LF & _
		"cp /mnt/install/repo/isolinux/hpssacli /tmp/hpssacli" & @LF & _
		"chmod +x /tmp/hpssacli" & @LF & _
		"cp /mnt/install/repo/isolinux/HPRaid.sh /tmp/HPRaid.sh" & @LF & _
		"chmod +x /tmp/HPRaid.sh" & @LF & _
		"/tmp/HPRaid.sh" & @LF & _
		"fi" & @LF & _
		"# get network info matching current serial number from network.csv file" & @LF & _
		"ipaddr=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $2}')" & @LF & _
		"netmask=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $3}')" & @LF & _
		"gw=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $4}')" & @LF & _
		"name=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $5}')" & @LF & _
		"domain=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $6}')" & @LF & _
		"ns=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $7}')" & @LF & _
		"tz=$(grep -i $serial /tmp/network.csv | awk -F',' '{print $10}')" & @LF & _
		"ctz=$(timedatectl | grep 'Time zone'| awk -F' ' '{print $3}')" & @LF & _
		"if [[ $ctz != $tz ]]; then $(timedatectl set-timezone $tz); fi" & @LF & _
		"#create ifcfg file for network manager using IP from server-list file" & @LF & _
		"echo 'NAME='$eth'" & @LF & _
		"DEVICE='$eth'" & @LF & _
		"ONBOOT=yes" & @LF & _
		"BOOTPROTO=none" & @LF & _
		"IPADDR='$ipaddr'" & @LF & _
		"NETMASK='$netmask'" & @LF & _
		"TYPE=Ethernet' >  /etc/sysconfig/network-scripts/ifcfg-$eth" & @LF & _
		"#set gw" & @LF & _
		"echo 'NOZEROCONF=yes" & @LF & _
		"NETWORKING=yes" & @LF & _
		"NETWORKING_IPV6=no" & @LF & _
		"GATEWAY='$gw > /etc/sysconfig/network" & @LF & _
		@LF & _
		"#config hostname" & @LF & _
		"echo $name > /etc/hostname" & @LF & _
		@LF & _
		"#config resolv" & @LF & _
		"echo 'domain '$domain'" & @LF & _
		"nameserver 155.179.59.249' > /etc/resolv.conf"

Local $2nd = "chmod +x /mnt/sysimage/tmp/create_osdisk_udevrules" & @LF & _
		"cp /mnt/install/repo/isolinux/postreboot.sh  /mnt/sysimage/tmp/postreboot.sh" & @LF & _
		"chmod +x /mnt/sysimage/tmp/postreboot.sh"

Local $3rd = "/bin/rm /etc/modprobe.d/anaconda-blacklist.conf" & @LF & _
		"# Postreboot procedure" & @LF & _
		"cp /etc/rc.d/rc.local /tmp/" & @LF & _
		"echo 'nohup /tmp/postreboot.sh >> /tmp/postinstall.log 2>&1 &' >> /etc/rc.d/rc.local" & @LF & _
		"chmod +x /etc/rc.d/rc.local"

Local $delresolve = "# build resolv.conf" & @LF & _
		"cat >> /tmp/resolv.conf.tmp <<EOF" & @LF & _
		"domain $(dnsdomainname)" & @LF & _
		"$(grep nameserver /etc/resolv.conf)" & @LF & _
		"EOF" & @LF & _
		@LF & _
		"/bin/cp /tmp/resolv.conf.tmp /etc/resolv.conf"
Local $delnetwork = "# Shorten the hostname to just the host, not the FQDN and add NOZEROCONF" & @LF & _
		"sed " & '"' & "s/`grep HOSTNAME /etc/sysconfig/network | awk -F= '{print $2}'`/`grep HOSTNAME /etc/sysconfig/network | awk -F= '{print $2}' | awk -F. '{print $1}'`/" & '"' & " / etc / sysconfig / network > /tmp / network.tmp" & @LF & _
		@LF & _
		"cat /etc/hostname | awk -F. '{print $1}' > /tmp/hostname.tmp" & @LF & _
		"/bin/cp /tmp/hostname.tmp /etc/hostname" & @LF & _
		@LF & _
		"# Clean up ifcfg-eth files" & @LF & _
		@LF & _
		"sed -i '/^BROADCAST/d; /^DNS/d; /^GATEWAY/d; /NM_CONTROLLED/d; /UUID/d' /etc/sysconfig/network-scripts/ifcfg-e*" & @LF & _
		"sed -i '/^BROADCAST/d; /^DNS/d; /^GATEWAY/d; /NM_CONTROLLED/d; /UUID/d' /etc/sysconfig/network-scripts/ifcfg-p*" & @LF & _
		"sed -i 's/dhcp/none/g' /etc/sysconfig/network-scripts/ifcfg-e*" & @LF & _
		"sed -i 's/dhcp/none/g' /etc/sysconfig/network-scripts/ifcfg-p*" & @LF & _
		@LF & _
		"echo " & '"' & "NOZEROCONF = yes" & '"' & " >> /tmp/network2.tmp" & @LF & _
		@LF & _
		"if grep -q GATEWAY /etc/sysconfig/network; then" & @LF & _
		"  echo " & '"' & "GATEWAY setup in network file already" & '"' & @LF & _
		"else" & @LF & _
		"  echo " & '"' & "GATEWAY=$(/sbin/ip route | grep default | tail -1 | /bin/awk '{print $3}')" & '"' & " >> /tmp/network2.tmp" & @LF & _
		"fi" & @LF & _
		@LF & _
		"/bin/cp /tmp/network2.tmp /etc/sysconfig/network" & @LF & _
		@LF
isolinux($isolinux)

Get_ks($ks)

Local $sFhead = "dal-HTTP-RH7.2-64"
Local $sRhead = "ks"
Local $sFurl = "--url http://thingz.ECORP.com/pub/kickstart/dist/rhel-x86_64-server-7.2"
Local $sRurl = $url
Local $sFtz = "US/Central"
Local $sRtz = $timezone
Local $sF1st = "#!/bin/sh"
Local $sF2nd = "chmod +x /mnt/sysimage/tmp/create_osdisk_udevrules"
Local $sF3rd = "/bin/rm /etc/modprobe.d/anaconda-blacklist.conf"
Local $sFsleep = "sleep 5"
Local $sRsleep = "sleep 60"

Local $iRetval = _ReplaceStringInFile($ks, $sFhead, $sRhead)
If $iRetval = -1 Then
	MsgBox($MB_SYSTEMMODAL, "ERROR", "The pECORPern could not be replaced in file: " & $ks & " Error: " & @error)
	Exit
EndIf
_ReplaceStringInFile($ks, $sFurl, $sRurl)
_ReplaceStringInFile($ks, $sFtz, $sRtz)
_ReplaceStringInFile($ks, $sFsleep, $sRsleep)
_ReplaceStringInFile($ks, $sF1st, $1st)
_ReplaceStringInFile($ks, $delresolve, "")
_ReplaceStringInFile($ks, $delnetwork, "")
_ReplaceStringInFile($ks, $sF3rd, $3rd)
_ReplaceStringInFile($ks, $sF2nd, $2nd)
_ReplaceStringInFile($postreboot, "@UserName", $user)
_ReplaceStringInFile($postreboot, "$mail", $mail)
_ReplaceStringInFile($fcsv, @CRLF, @LF)

If FileExists($ks) And FileExists($isolinux) Then
	FileCopy($ks, @TempDir & "\extract\isolinux\", 1)
	FileCopy($isolinux, @TempDir & "\extract\isolinux\", 1)
	FileCopy(@ScriptDir & "\network.csv", @TempDir & "\extract\isolinux\", 1)
	FileCopy(@TempDir & "\hpssacli", @TempDir & "\extract\isolinux\", 1)
	FileCopy(@TempDir & "\HPRaid.sh", @TempDir & "\extract\isolinux\", 1)
	FileCopy(@TempDir & "\postreboot.sh", @TempDir & "\extract\isolinux\", 1)
	;# mkisofs -o ../your-new.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V Your Disk Name Here .
	RunWait(@ComSpec & " /c " & @TempDir & "\mkisofs.exe -o " & @ScriptDir & "\ECORP_RHEL7.2_x86_64-" & $domain & ".iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -r -V ECORP-RHEL7 -x EFI -x images -x isolinux.cfg.orig -x upgrade.img -x \[BOOT] -x pxeboot .", @TempDir & "/extract/")
	If @error Then
		MsgBox(4096, "mkisofs", "Repacking ISO failed! Error code: " & @error)
		Exit
	EndIf
EndIf
;~~~~~~~~~~~~HW~~~~~~~~~
If $system = "HW" Then
	$SFTP = InputBox("Do we have a victim?", "Where should I put the ISO?", $victim)
	If StringInStr($SFTP, ".com") Then
		TCPStartup()
;~ 		RunWait(@ScriptDir & '\winscp.com /ini=nul /command "open sftp://root:geton@' & $SFTP & '/ -hostkey=*" "put ' & @ScriptDir & '\ECORP_RHEL7.2_x86_64-' & $domain & '.iso" "put ' & @ScriptDir & '\mgmt-list" "put ' & @ScriptDir & '\build_pack\*" "exit"')
		RunWait(@ScriptDir & '\winscp.com /ini=nul /command "open sftp://user@' & $SFTP & '/ -hostkey=* -privatekey=C:\Work\Securecrt\Config\peter.ppk" "put ' & @ScriptDir & '\ECORP_RHEL7.2_x86_64-' & $domain & '.iso" "put ' & @ScriptDir & '\mgmt-list" "put ' & @ScriptDir & '\build_pack\*" "exit"')
		Sleep(2000)
;~~~~~~~~~~~~HP~~~~~~~~~
		If $type = "HP" Then
			RunWait('cmd.exe /c echo y | ' & @TempDir & '\plink.exe -ssh -i "C:\Work\Securecrt\Config\peter.ppk" ' & $SFTP & ' chmod +x `pwd`/isoserve `pwd`/Load_ILO_ISO.ksh', @TempDir)
			Sleep(2000)
;~ 			RunWait(@TempDir & '\plink.exe -ssh -l root -pw geton ' & $SFTP & ' nohup /root/isoserve -dir="/root/" -port "80" & nohup /root/Load_ILO_ISO.ksh -l /root/mgmt-list -u USERID -p password -H http://' & TCPNameToIP($SFTP) & '/ -I ECORP_RHEL7.2_x86_64-' & $domain & '.iso', @TempDir)
			RunWait(@TempDir & '\plink.exe -ssh -i "C:\Work\Securecrt\Config\peter.ppk" ' & $SFTP & ' nohup `pwd`/isoserve -dir="`pwd`/" -port "8765" & nohup `pwd`/Load_ILO_ISO.ksh -l `pwd`/mgmt-list -u USERID -p password -H http://' & TCPNameToIP($SFTP) & ':8765/ -I ECORP_RHEL7.2_x86_64-' & $domain & '.iso', @TempDir)
			TCPShutdown()
;~~~~~~~~~~~~Dell~~~~~~~~~
		ElseIf $type = "Dell" Then
;~ 		RunWait('cmd.exe /c echo y | ' & @TempDir & '\plink.exe -ssh -l root -pw geton ' & $SFTP & ' chmod +x /root/isoserve /root/Load_ILO_ISO.ksh', @TempDir)
;~ 		Sleep(2000)
;~ 		RunWait(@TempDir & '\plink.exe -ssh -l root -pw geton ' & $SFTP & ' nohup /root/isoserve -dir="/root/" -port "80" & nohup /root/Load_ILO_ISO.ksh -l /root/mgmt-list -u USERID -p password -H http://' & TCPNameToIP($SFTP) & '/ -I ECORP_RHEL7.2_x86_64-' & $domain & '.iso', @TempDir)
			#cs
				Check Virtual disks:
				/nas/usr/sbc/SI/linux_tools/ACD/iDRAC/bin/Get_Vdisks.ksh -l mgmt-list -u USERID -p password

				Delete Virtual disks (if any):
				/nas/usr/sbc/SI/linux_tools/ACD/iDRAC/bin/Remove_Virtual_Disks.ksh -l mgmt-list -u USERID -p password

				Create OS disks:
				/nas/usr/sbc/SI/linux_tools/ACD/iDRAC/bin/Create_Vdisk.ksh -l mgmt-list -u USERID -p password -c disk-config -t OS

				Create Data disk:
				/nas/usr/sbc/SI/linux_tools/ACD/iDRAC/bin/Create_Vdisk.ksh -l mgmt-list -u USERID -p password -c disk-config -t R10

				while read line; do /opt/dell/srvadmin/sbin/racadm -r $line -u USERID -p password config -g cfgServerInfo -o cfgServerFirstBootDevice vCD-DVD ; /opt/dell/srvadmin/sbin/racadm -r $line -u USERID -p password config -g cfgServerInfo -o cfgServerBootOnce 1; done < mgmt-list

				while read line; do echo "nohup vmcli -r $line  -u USERID -p password -c ECORP_RHEL7.2_x86_64-' & $domain & '.iso &"; done < mgmt-list

				while read line; do /opt/dell/srvadmin/sbin/racadm -r $line -u USERID -p password serveraction powercycle; done < mgmt-list
			#ce
			TCPShutdown()
		EndIf
		_DebugOut("Finished @ " & @HOUR & ":" & @MIN)
	EndIf
;~~~~~~~~~~~~VM~~~~~~~~~
ElseIf $system = "VM" Then
	If StringInStr($aTmp[0][4], ".") Then
		$VC = Get_VC(StringSplit($aTmp[0][4], ".")[1])
	Else
		$VC = Get_VC($aTmp[0][4])
		Run('"C:\Program Files (x86)\VMware\Infrastructure\Virtual Infrastructure Client\Launcher\VpxClient.exe"' & ' -u ' & $user & ' -p ' & $pass & ' -s ' & $VC)

		Global $hvSpClient = WinWait("[REGEXPTITLE:.*com - vSphere Client]")

		If _DebugOut("vSphere ", $hvSpClient) Then _ArrayDisplay($aVMtxt, "VMs to be installed")
		WinActivate($hvSpClient)
		ControlSend($hvSpClient, "", "[NAME:m_mainMenu]", "{alt}wis")

		For $i = 0 To UBound($aVMtxt) - 1 ; Loop through the array.
			Global $cVM = $aVMtxt[$i]
			_DebugOut($cVM & @CRLF)
			;start some shiet
			WinActivate($hvSpClient)

			ControlSetText($hvSpClient, "", "[NAME:mSimpleSearchBox]", "")
			ControlSend($hvSpClient, "", "[NAME:mSimpleSearchBox]", $cVM)
			Sleep(200)
			ControlSend($hvSpClient, "", "[NAME:mSimpleSearchBox]", "{enter}")
			If Not ControlGetText($hvSpClient, "", "[NAME:mSimpleSearchBox]") == $cVM Then MsgBox(0, "search", "failed")
			;Local $iCount = 1

			Do
				$Finish = ControlGetText($hvSpClient, "1 result for " & $cVM, "[Name:mLabelResultsCount]")
				Sleep(500)
				;$iCount += 1
			Until $Finish = StringRegExp($Finish, '1 result for ' & '"' & $cVM & '"' & ' in inventory at .*') ; or $iCount > 10
			_DebugOut($Finish & @CRLF)

			Sleep(1000)

			Do
				$Poff = PixelSearch(23, 284, 25, 289, 0x2164BA, 10, 1)
				$Pon = PixelSearch(23, 284, 25, 289, 0x68D03F, 10, 1)
				Sleep(500)
				If $Pon Or $Poff = 1 Then ExitLoop
			Until IsArray($Pon) = 1 Or IsArray($Poff) = 1

			If IsArray($Pon) = 1 Then
				$asking = MsgBox(3, "VM Status - Power On", "should we skip this one", 0, $hvSpClient)
				If $asking = 6 Then ContinueLoop
				If $asking = 2 Then Exit
			EndIf

			If IsArray($Poff) = 1 Then
				_DebugOut("VM it's off" & @CR)
			EndIf
			Opt("SendKeyDelay", 50)

			ControlSend($hvSpClient, "", $searchH, "{home}")
			Sleep(100)
			ControlSend($hvSpClient, "", "[NAME:m_mainMenu]", "{altdown}nvl{altup}")

			Global $console = WinWait($cVM & " on ", "", 5)

			_DebugOut("Console: " & $console & @CRLF)
			WinActivate($console)

			Call($mount)
			Sleep(3000)
			$Finish = WinGetClientSize($console)
			Do
				Sleep(500) ;740, 529
				;Until $Finish[0] = 722 And $Finish[1] = 482 Or $Finish[0] >= 720 And $Finish[1] >= 400
			Until $Finish[0] <> WinGetClientSize($console)[0] And $Finish[1] <> WinGetClientSize($console)[1]
			_DebugOut("booting..." & @CRLF)
			Sleep(3000)

			Global $WinLoc = WinGetPos($console)
			If @error Then
				MsgBox(0, 'you suck', '')
				Exit
			EndIf
		Next
	EndIf
EndIf
TrayTip("Completed!", "tanaaaa", 5)

FileRecycle(@TempDir & "\7z.exe")
FileRecycle(@TempDir & "\plink.exe")
FileRecycle(@TempDir & "\cygwin1.dll")
FileRecycle(@TempDir & "\mkisofs.exe")
FileRecycle(@TempDir & "\HPRaid.sh")
FileRecycle(@TempDir & "\hpssacli")
FileRecycle(@TempDir & "\extract")

Func Get_SN($cHost)
	Global $timeout = ($ping + 30000)

	$type = StringMid($cHost, 4, 1)
	Select
;~~~~~HP~~~~~
		Case $type = "h"
			Global $system = "HW"
			Global $type = "HP"
			Global $cPID = Run(@TempDir & "\plink.exe -ssh -l USERID -pw password " & $cHost & $mgmtdomain & "  show /system1 number", @TempDir, Default, 0x1 + 0x8)
;~~~~~Dell~~~~~
		Case $type = "d"
			Global $system = "HW"
			Global $type = "Dell"
			Global $cPID = Run(@TempDir & "\plink.exe -ssh -l USERID -pw password " & $cHost & $mgmtdomain & "  racadm getsvctag", @TempDir, Default, 0x1 + 0x8)
;~ 			Global $cPID = Run(@TempDir & "\plink.exe -ssh -l USERID -pw password " & $cHost & "-mgmt." & $domain & "  show /admin1/hdwr1/chassis1", @TempDir, Default, 0x1 + 0x8)
;~~~~~Hitachi~~~~~
		Case $type = "o"
			Global $system = "HW"
			Global $type = "Hitachi"
			Global $cPID = Run(@TempDir & "\plink.exe -ssh -l linux -pw password " & $cHost & $mgmtdomain, @TempDir, Default, 0x1 + 0x8)
		Case Else ; If nothing matches then execute the following.
			MsgBox($MB_SYSTEMMODAL, "", "Ce plm e asta?" & $cHost & " - " & $type)
			Exit
	EndSelect


;~ 	If $type = "HP" Then Global $cPID = Run(@TempDir & "\plink.exe -ssh -l USERID -pw password " & $cHost & "-mgmt." & $domain & "  show /system1 number", @TempDir, Default, 0x1 + 0x8)
;~ 	If $type = "Dell" Then Global $cPID = Run(@TempDir & "\plink.exe -ssh -l USERID -pw password " & $cHost & "-mgmt." & $domain & "  show /admin1/hdwr1/chassis1", @TempDir, Default, 0x1 + 0x8)
;~ 	If $type = "Hitachi" Then Global $cPID = Run(@TempDir & "\plink.exe -ssh -l linux -pw password " & $cHost & "-mgmt." & $domain, @TempDir, Default, 0x1 + 0x8)
;~ 	If $type = "Hitachi" Then Global $cPID = Run(@TempDir & "\plink.exe -ssh -l linux -pw password " & $cHost & "-mgmt." & $domain & "  show chassis setting", @TempDir, Default, 0x1 + 0x8)
;~ 	If $type = "Dell" Then Global $cPID = Run(@TempDir & "\plink.exe -ssh -l linux -pw password " & $cHost & "-mgmt." & $domain & "  show /admin1/hdwr1/chassis1", @TempDir, Default, 0x1 + 0x8)
;~ 	If $type = "Dell" Then Global $cPID = Run(@TempDir & "\plink.exe -ssh -l root -pw calvin " & $cHost & "-mgmt." & $domain & "  show /admin1/hdwr1/chassis1", @TempDir, Default, 0x1 + 0x8)
;~ 	If StringMid($cHost, 4, 1) = "h" Then $cPID = Run(@TempDir & "\plink.exe -ssh -l linux -pw password " & $cHost & "-mgmt." & $domain & "  show /system1 number", @TempDir, Default, 0x1 + 0x8)

	$waitForOutputStartTime = TimerInit()
	$plinkFeedback = ""

	Do
		Sleep(100)
		Global $cOUT = StdoutRead($cPID)
		If $cOUT <> "" Then _DebugReportVar("plink", $cOUT)

		If StringInStr($cOUT, "FATAL ERROR: Network error: Network is unreachable") Then
			$cOUT = "OFFLINE"
			_DebugOut($cOUT)
			Return $cOUT
			ExitLoop
		EndIf

		If StringInStr($cOUT, "Store key") Then
			StdinWrite($cPID, "y" & @CRLF & @CRLF)
			Sleep(2000)
			$cOUT = StdoutRead($cPID)
		EndIf
		If $type = "HP" And StringInStr($cOUT, "number") Then
			$cOUT = _StringBetween($cOUT, "number=", @CRLF)[0]
			_DebugOut($cOUT)
			Return $cOUT
			ExitLoop
		EndIf
		If $type = "Dell" And $cOUT <> "" Then
			$cOUT = _StringBetween($cOUT, "", @LF)[0]
			_DebugOut($cOUT)
			Return $cOUT
			ExitLoop
		EndIf
		If $type = "Hitachi" And StringInStr($cOUT, "$") Then
			StdinWrite($cPID, "show chassis setting" & @LF)
			Sleep(2000)
			$cOUT = StdoutRead($cPID)
			$cOUT = _StringBetween($cOUT, "Serial number                  : ", "  " & @CRLF)[0]
			_DebugOut($cOUT)
			Return $cOUT
			ExitLoop
		EndIf
		If StringInStr($cOUT, "password") Or StringInStr($cOUT, "denied") Then
			Return False
		EndIf

		$plinkFeedback &= StdoutRead($cPID)
		$stdoutReadError = @error

	Until $stdoutReadError Or ($timeout And TimerDiff($waitForOutputStartTime) > $timeout)
;~ 	If ProcessExists($cPID) Then ProcessClose($cPID)

	Return False
EndFunc   ;==>Get_SN

Func isolinux($isolinux)
	If FileExists($isolinux) Then FileMove($isolinux, @TempDir & "\isolinux" & @SEC & ".cfg.old", 1)
	; Create a temporary file to write data to.
	If Not FileWrite($isolinux, "default vesamenu.c32" & @LF) Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the isolinux.cfg file.")
		Exit
	EndIf

	; Open the file for writing (append to the end of a file) and store the handle to a variable.
	Local $hFileOpen = FileOpen($isolinux, $FO_APPEND)
	If $hFileOpen = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the isolinux.cfg file.")
		Exit
	EndIf

	; Write data to the file using the handle returned by FileOpen.
	FileWrite($hFileOpen, "timeout 1" & @LF)
	FileWrite($hFileOpen, "label RHEL7" & @LF)
	FileWrite($hFileOpen, "  kernel vmlinuz" & @LF)
	FileWrite($hFileOpen, "  append initrd=initrd.img inst.stage2=hd:LABEL=ECORP-RHEL7 inst.ks=cdrom:/dev/cdrom:/isolinux/ks.cfg modprobe.blacklist=qla2xxx,lpfc inst.text nameserver= " & $ns)

	; Close the handle returned by FileOpen.
	FileClose($hFileOpen)

EndFunc   ;==>isolinux

Func Get_ks($ks)
	; Save the downloaded file to the temporary folder.
	If FileExists($ks) Then FileMove($ks, @TempDir & "\ks" & @SEC & ".cfg.old", 1)

	; Download the file in the background with the selected option of 'force a reload from the remote site.'
	Local $hDownload = InetGet("http://rhnsat.domain.com/pub/kickstart/sd/7.2/dal-HTTP-RH7.2-64.cfg", $ks, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)

	; Wait for the download to complete by monitoring when the 2nd index value of InetGetInfo returns True.
	Do
		Sleep(250)
	Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)

	; Retrieve the number of total bytes received and the filesize.
	Local $iBytesSize = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
	Local $iFileSize = FileGetSize($ks)

	; Close the handle returned by InetGet.
	InetClose($hDownload)

	If $iFileSize <> 9512 Then
		MsgBox($MB_SYSTEMMODAL, $ks, "Incorrect Size or the default Kickstart configuration has changed." & @CRLF & _
				"The total download size: " & $iBytesSize & @CRLF & _
				"The total filesize: " & $iFileSize & @CRLF & _
				"Filename: " & $ks & _
				"Exprected size: 9512")
		Exit
	EndIf

EndFunc   ;==>Get_ks

Func Get_UUID($VM)
	$source = _INetGetSource($urlUUID & $VM) ;get html
	Local $readUUID = _StringBetween($source, '<td width=25%>', '</td>') ;read URL and title from file
	If IsArray($readUUID) And UBound($readUUID) == 3 Then
		VM_hosts($VM)
		Return $readUUID[2]
	Else
		MsgBox(64, "Finished", "Couldn't find UUID for " & $VM)
		Exit
	EndIf
EndFunc   ;==>Get_UUID

Func Get_VC($VM)
	$source = _INetGetSource($urlUUID & $VM) ;get html
	Local $readVC = _StringBetween($source, 'VcenterName=', '"') ;read URL and title from file
	If IsArray($readVC) And UBound($readVC) == 2 Then
		$VC = StringReplace($readVC[1], "%2E", ".")
		Return $VC
	Else
		MsgBox(64, "Finished", "Couldn't find vCenter for " & $VM)
		Exit
	EndIf
EndFunc   ;==>Get_VC

Func Guess_net_info($host)
	_DebugReportVar("Guessing host info", $host)
	$row = _ArraySearch($aXls, $host, 0, 0, 0, 1, 1, -1, False)
	If $row = -1 Then
		MsgBox(0, "Incorrect Network Design", "IP Address not found: " & $host)
		Exit
	EndIf
	$col = _ArraySearch($aXls, $host, 0, 0, 0, 1, 1, -1, True)
	Global $maskxy = $aXls[$row][$mask_col]
	If StringInStr($maskxy, "/") <> 0 Then $maskxy = StringSplit($maskxy, "/")[1]
	Global $gwxy = $aXls[$row][$gw_col]
	Global $hostnamexy = StringStripWS(StringLower($aXls[$row][$hostname_col]), 8)
	Local $perv
	If StringLen($hostnamexy) >= 8 Then
		$hostname_split = StringSplit($hostnamexy, ".")
		Global $hostnamexy = $hostname_split[1]
	EndIf
	Global $ipxy = TCPNameToIP($hostnamexy & "." & $domain)
	If $ipxy = "" Then MsgBox(0, "No IP found", "couldn't find the IP for " & $hostnamexy)
	$aXls[$row][$ip_col] = StringStripWS($aXls[$row][$ip_col], 8)
	If $ipxy <> $aXls[$row][$ip_col] Then MsgBox(0, "monkey", "network design ip: '" & $aXls[$row][$ip_col] & "'" & @CRLF & "DNS record: '" & $ipxy & "'")
	If $perv = $hostnamexy Then Return
	$perv = $hostnamexy
	_DebugOut("<<Host info>> " & $ipxy & "," & $maskxy & "," & $gwxy & "," & $hostnamexy & "," & $domain & "," & $ns & "," & $ns1 & "," & $ns2 & "," & $timezone)
	If TCPNameToIP($hostnamexy & ".enaf." & $domain) <> "" Then
		$domain = "enaf." & $domain
		_DebugOut("We haz enaf! " & $hostnamexy & "." & $domain & @CRLF)
	EndIf
	Local $sSingleFill = [[$ipxy, $maskxy, $gwxy, $hostnamexy, $domain, $ns, $ns1, $ns2, $timezone]]
	_ArrayAdd($aTmp, $sSingleFill)
EndFunc   ;==>Guess_net_info

Func VM_hosts($VM)
	Local $hFileOpen = FileOpen($vmtxt, 1)
	; Create a temporary file to write data to.
	If $hFileOpen = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the VM hosts file.")
		Return False
	EndIf

	; Write data to the file using the handle returned by FileOpen.
	FileWriteLine($hFileOpen, $VM & @CRLF)

	; Close the handle returned by FileOpen.
	FileClose($hFileOpen)
EndFunc   ;==>VM_hosts

Func DC_guess($hostname)
	$aDCResult = _ArrayFindAll($aDC, StringMid($hostname, 1, 1), Default, Default, Default, Default, 0, True)
	If $aDCResult >= 0 Then
		DC($aDCResult[0])
	Else
		If IsArray(StringRegExp($hostname, "(\d+)\.(\d+)\.(\d+)\.(\d+)", 1)) Then
			MsgBox(0, "ERROR", "Incorrect network info" & @CRLF & "Expecting hostname but got IP" & @CRLF & "exiting...")
			Exit
		EndIf
		MsgBox(4096, "ERROR", "Unknown hostname: " & $hostname & @CRLF & "Error: " & @error)
		Global $domain = InputBox("Domain", "Input Domain Name", "ffdc.DOMAIN.com", "", 220, 150)
		$aDCResult = _ArrayFindAll($aDC, $domain, Default, Default, Default, Default, 2, True)
		If $aDCResult >= 0 Then
			DC($aDCResult[0])
		EndIf
	EndIf
EndFunc   ;==>DC_guess

Func DC($x)
	Global $url = $aDC[1][$x]
	Global $domain = $aDC[2][$x]
	Global $timezone = $aDC[3][$x]
	Global $ns = $aDC[4][$x]
	Global $ns1 = $aDC[5][$x]
	Global $ns2 = $aDC[6][$x]
EndFunc   ;==>DC

Func DSISO() ;mount from datastore
	Opt("SendKeyDelay", 100)
	ControlSend($console, "", "[NAME:PowerOnButton]", "{space}")
	Do
		$Finish = WinGetClientSize($console)
		_DebugOut($console & @CRLF)
		Sleep(1000)
	Until $Finish[0] > 500
	ControlSend($console, "", "[NAME:CDDeviceConnectionsButton]", "{space}{down}{right}{end}{enter}")
	$open = WinWait("[TITLE:Browse Datastores; CLASS:WindowsForms10.Window.8.app.0.ef627a]", "")
	While $open <> 0
		ControlSend($open, "", "[NAME:mButtonUpOneLevel]", "{space}")
		Sleep(1000)
		ControlSend($open, "", "[NAME:mButtonUpOneLevel]", "{space}")
		Sleep(1000)
		ControlSend($open, "", "[NAME:mButtonUpOneLevel]", "{space}")
		Sleep(1000)
		ControlSend($open, "", "[NAME:mButtonUpOneLevel]", "{space}")
		Sleep(1000)
		ControlSend($open, "", "", "{end}{up 5}{enter}")
		Sleep(1000)
		ControlSend($open, "", "", "{down 5}{enter}")
		Sleep(1000)
		ControlSend($open, "", "", "{down}{enter}")
		Sleep(2000)
		ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
		$open = WinWait("[TITLE:Browse Datastores; CLASS:WindowsForms10.Window.8.app.0.ef627a]", "", 1)
	WEnd
	$Finish = WinGetClientSize($console)
	If Not ($Finish[0] > 492 And $Finish[1] > 473) Then
		Do
			$Finish = WinGetClientSize($console)
			Sleep(2000)
		Until $Finish[0] > 492 And $Finish[1] > 473
		ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
	EndIf
EndFunc   ;==>DSISO

Func MISO()
	Do
		$Finish = WinGetClientSize($console)
		Sleep(500)
	Until $Finish[0] > 720 And $Finish[1] > 481

	ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
EndFunc   ;==>MISO

Func LISO()
	$iso_path = @ScriptDir & "\ECORP_RHEL7.2_x86_64-" & $domain & ".iso"
	$Finish = WinGetClientSize($console)
	If Not ($Finish[0] > 492 And $Finish[1] > 473) Then
		ControlSend($console, "", "[NAME:PowerOnButton]", "{space}")
		Do
			$Finish = WinGetClientSize($console)
			Sleep(500)
		Until $Finish[0] > 492 And $Finish[1] > 473
	EndIf
	Sleep(2000)
	ControlSend($console, "", "[NAME:CDDeviceConnectionsButton]", "{space}{down}{right}{enter}")
	$open = WinWait("[TITLE:Open; CLASS:#32770]", "", 5)

	If $open = 0 Then
		ControlSend($console, "", "[NAME:CDDeviceConnectionsButton]", "{space}{down}{right}{enter}")
		$open = WinWait("[TITLE:Open; CLASS:#32770]", "")
		WinActivate($open)
		ControlSetText($open, "", "[CLASS:Edit; INSTANCE:1]", $iso_path)
		ControlSend($open, "", "[CLASS:Edit; INSTANCE:1]", "{enter}")
		Sleep(7000)
		ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
	Else
		WinActivate($open)
		ControlSetText($open, "", "[CLASS:Edit; INSTANCE:1]", $iso_path)
		ControlSend($open, "", "[CLASS:Edit; INSTANCE:1]", "{enter}")
		Sleep(7000)
		ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
	EndIf

	Opt("SendKeyDelay", 50)
EndFunc   ;==>LISO

Func hais()
	If MsgBox(1, "dude wtf", "tzo? totu bun?") = 2 Then Exit
EndFunc   ;==>hais

Func _Exit()
	Sleep(100)
	Exit
EndFunc   ;==>_Exit

