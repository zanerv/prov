#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <Excel.au3>
#AutoIt3Wrapper_Run_Debug_Mode=y
Opt("TrayIconDebug", 1)
Opt("WinTextMatchMode", 2) ;1=complete, 2=quick
Opt("MouseCoordMode", 2)
;Opt("SendKeyDelay", 50)
HotKeySet("{Esc}", "_Exit")
Global $nic = "eno16780032"
Global $cServer = "meh.com"
Global $retWin = WinGetHandle($cServer & " - vSphere Client")
HotKeySet("{F12}", "hais")
Global $mount = "MISO"
;Global $mount = "DSISO"
;Global $mount = "LISO"
ConsoleWrite($retWin & @CRLF)

; Create application object and open an example workbook
Local $oExcel = _Excel_Open()
If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel", "Error creating the Excel application object." & @CRLF & "@error = " & @error & ", @extended = " & @extended)
Local $oWorkbook = _Excel_BookOpen($oExcel, "C:\Work\Slice and dice.xls")
If @error Then
	MsgBox($MB_SYSTEMMODAL, "Excel", "Error opening workbook 'C:\Work\Slice and dice.xls'." & @CRLF & "@error = " & @error & ", @extended = " & @extended)
	_Excel_Close($oExcel)
	Exit
EndIf
Local $sResult = _Excel_RangeRead($oWorkbook, Default)
If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel", "Error reading from workbook." & @CRLF & "@error = " & @error & ", @extended = " & @extended)

If StringRegExp($sResult[0][0], "FQDN") = 1 Then
	ConsoleWrite("Sters la cur ->" & $sResult[0][0] & @CR)
	_ArrayDelete($sResult, 0)
EndIf

WinActivate($retWin)
ControlSend($retWin, "", "[NAME:m_mainMenu]", "{alt}wis")

;_ArrayDisplay($sResult)
For $i = 0 To UBound($sResult) - 1 ; Loop through the array.
	$fqdn = StringRegExp($sResult[$i][0], "(.net|.com)$")
	If $fqdn Then
		$host = StringSplit($sResult[$i][0], ".")
		Global $cVM = $host[1]
		ConsoleWrite($cVM & @CRLF)
	Else
		Global $cVM = $sResult[$i][0]
	EndIf
	$ip = " ip=" & $sResult[$i][3] & "::" & $sResult[$i][2] & ":" & $sResult[$i][1] & ":" & $cVM & ":" & $nic & ":none"
	ConsoleWrite($ip & @CRLF)

	ConsoleWrite($sResult[$i][0] & @CR) ; Display the contents of the array.
	;start some shiet

	WinActivate($retWin)

	ControlSetText($retWin, "", "[NAME:mSimpleSearchBox]", "")
	ControlSend($retWin, "", "[NAME:mSimpleSearchBox]", $cVM)
	Sleep(200)
	ControlSend($retWin, "", "[NAME:mSimpleSearchBox]", "{enter}")
	;_ControlMouseClick($retWin, "", "[NAME:mBtnSearch]", "primary")
	If Not ControlGetText($retWin, "", "[NAME:mSimpleSearchBox]") == $cVM Then MsgBox(0, "search", "failed")
	;Local $iCount = 1

	Do
		$Finish = ControlGetText($retWin, "1 result for " & $cVM, "[Name:mLabelResultsCount]")
		Sleep(500)
		ConsoleWrite($Finish & @CRLF)
		;$iCount += 1
	Until $Finish = StringRegExp($Finish, '1 result for ' & '"' & $cVM & '"' & ' in inventory at .*') ; or $iCount > 10

	;If $iCount > 10 Then

	Sleep(1000)

	Do
		$Poff = PixelSearch(23, 284, 25, 289, 0x2164BA, 10, 1)
		$Pon = PixelSearch(23, 284, 25, 289, 0x68D03F, 10, 1)
		Sleep(500)
		If $Pon Or $Poff = 1 Then ExitLoop
	Until IsArray($Pon) = 1 Or IsArray($Poff) = 1

	If IsArray($Pon) = 1 Then
		$asking = MsgBox(3, "VM Status - Power On", "should we skip this one", 0, $retWin)
		If $asking = 6 Then ContinueLoop
		If $asking = 2 Then Exit
	EndIf

	If IsArray($Poff) = 1 Then
		ConsoleWrite("pixeliii it`s off" & @CR)
	EndIf

	ControlSend($retWin, "", "[CLASS:WindowsForms10.SysListView32.app.0.ef627a; INSTANCE:1]", "{home}")
	Sleep(100)
	ControlSend($retWin, "", "[NAME:m_mainMenu]", "{altdown}nvl{altup}")

	Global $console = WinWait($cVM & " on ", "", 5)

	ConsoleWrite("Console: " & $console & @CRLF)
	WinActivate($console)

	Call($mount)
	Do
		$Finish = WinGetClientSize($console)
		Sleep(500)
	Until $Finish[0] = 722 And $Finish[1] = 482 Or $Finish[0] >= 642 And $Finish[1] >= 562
	ConsoleWrite("booting..." & @CRLF)
	Sleep(3000)

	Local $WinLoc = WinGetPos($console)
	If @error Then
		MsgBox(0, 'you suck', '')
		Exit
	EndIf

	Opt("SendKeyDelay", 50)

	MouseClick("primary", ($WinLoc[2] / 2), ($WinLoc[3] / 2))

	Send(DC($fqdn))
	Send("{tab}")
	Send($ip)
	Send("{enter}")
	Send("{CTRLDOWN}{ALTDOWN}{ALTUP}{CTRLUP}")
	Opt("SendKeyDelay", 5)
Next


Func _Exit()
	Exit
EndFunc   ;==>_Exit
Func hais()
	If MsgBox(1, "dude wtf", "tzo? totu bun?") = 2 Then Exit
EndFunc   ;==>hais

Func _ControlMouseClick($iTitle, $iText, $iControl, $iButton = "left", $iClicks = "1", $iSpeed = "0", $iXpos = "", $iYpos = "")
	$iOriginal = Opt("MouseCoordMode") ;Get the current MouseCoordMode
	Opt("MouseCoordMode", 2) ;Change the MouseCoordMode to relative coords
	$aPos = ControlGetPos($iTitle, $iText, $iControl) ;Get the position of the given control
	MouseClick($iButton, $aPos[0] + ($aPos[2] / 2) + $iXpos, $aPos[1] + ($aPos[3] / 2) + $iYpos, $iClicks, $iSpeed) ;Move the mouse and click on the given control
	Opt("MouseCoordMode", $iOriginal) ;Change the MouseCoordMode back to the original
EndFunc   ;==>_ControlMouseClick

Func DSISO()
	Opt("SendKeyDelay", 100)
	ControlSend($console, "", "[NAME:PowerOnButton]", "{space}")
	Do
		$Finish = WinGetClientSize($console)
		ConsoleWrite($console&@CRLF)
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
			;ConsoleWrite($Finish[0]&" "&$Finish[1]&" "&$console)
			Sleep(500)
		Until $Finish[0] > 720 And $Finish[1] > 481

		ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
EndFunc   ;==>MISO

Func LISO()
	If Not ($Finish[0] > 492 And $Finish[1] > 473) Then
		ControlSend($console, "", "[NAME:PowerOnButton]", "{space}")
		Do
			$Finish = WinGetClientSize($console)
			Sleep(500)
		Until $Finish[0] > 492 And $Finish[1] > 473
	EndIf

	ControlSend($console, "", "[NAME:CDDeviceConnectionsButton]", "{space}{down}{right}{enter}")
	$open = WinWait("[TITLE:Open; CLASS:#32770]", "", 5)
	Sleep(1000)
	If $open <> 0 Then
		ControlSetText($open, "", "[CLASS:Edit; INSTANCE:1]", "C:\Work\RHEL7_x86_64.iso")
		ControlSend($open, "", "[CLASS:Edit; INSTANCE:1]", "{enter}")
		Sleep(7000)
		ControlSend($console, "menuStrip1", "[NAME:menuStrip]", "{altdown}vgs{altup}")
	EndIf
EndFunc   ;==>LISO
Func DC($fqdn)
	If StringInStr($fqdn, "1.com") Then Return "{home}"
	If StringInStr($fqdn, "2.com") Then Return "{down 4}"
	If StringInStr($fqdn, "3.com") Then Return "{down 1}"
	If StringInStr($fqdn, "4.com") Then Return "{down 3}"
	If StringInStr($fqdn, "5.com") Then Return "{down 6}"
	If StringInStr($fqdn, "6.com") Then Return "{down 5}"
	If StringInStr($fqdn, "7.com") Then Return "{down 7}"
	If StringInStr($fqdn, "8.com") Then Return "{down 8}"
	If StringInStr($fqdn, "9.com") Then Return "{down 7}"
	If StringInStr($fqdn, "10.com") Then Return "{down 5}"
	If StringInStr($fqdn, "11.com") Then Return "{down 7}"
	If StringInStr($fqdn, "12.com") Then Return "{down 7}"
	If StringInStr($fqdn, "13.com") Then Return "{down 7}"
	If StringInStr($fqdn, "14.com") Then Return "{down 7}"
	If StringInStr($fqdn, "15.com") Then Return "{down 2}"
	If StringInStr($fqdn, "16.com") Then Return "{down 2}"
	If StringInStr($fqdn, "17.com") Then Return "{down 4}"
	If StringInStr($fqdn, "18.com") Then Return "{down 7}"
	If StringInStr($fqdn, "19.com") Then Return "{down 7}"
	If StringInStr($fqdn, "20.com") Then Return "{down 3}"
	If StringInStr($fqdn, "21.com") Then Return "{down 4}"
	If StringInStr($fqdn, "22.com") Then Return "{down 4}"
	If StringInStr($fqdn, "23.net") Then Return "{down 7}"
EndFunc   ;==>DC

