#!/bin/sh
Slot=$(/tmp/hpssacli ctrl all show config|grep 'Slot'|awk '{print $6}')
mod="/tmp/hpssacli ctrl slot=$Slot modify ep=medium"
delete=$(/tmp/hpssacli ctrl slot=$Slot delete forced)
rescan=$(/tmp/hpssacli rescan)
BoxBay=( $(/tmp/hpssacli ctrl slot=$Slot physicaldrive all show|grep physicaldrive|awk '{print $2}') )
OSDrives=${BoxBay[0]},${BoxBay[1]}
GHS="/tmp/hpssacli ctrl slot=$Slot array all add spares=${BoxBay[2]}"
unset BoxBay[0] BoxBay[1] BoxBay[2]
#APPDrives=${BoxBay[*]:3}
APPDrives=${BoxBay[@]}
phyDrives=$(/tmp/hpssacli ctrl slot=$Slot physicaldrive all show|grep -c physicaldrive)
APP0="/tmp/hpssacli ctrl slot=$Slot create type=LD drives=${APPDrives// /,} raid=0"
APP1="/tmp/hpssacli ctrl slot=$Slot create type=LD drives=${APPDrives// /,} raid=1"
APP5="/tmp/hpssacli ctrl slot=$Slot create type=LD drives=${APPDrives// /,} raid=5"
OS (){
	$(/tmp/hpssacli ctrl slot=$Slot create type=LD drives=$OSDrives size=71168 raid=1)
	$(/tmp/hpssacli ctrl slot=$Slot create type=LD drives=$OSDrives size=71168)
	$(/tmp/hpssacli ctrl slot=$Slot create type=LD drives=$OSDrives size=71168)
	$(/tmp/hpssacli ctrl slot=$Slot create type=LD drives=$OSDrives size=71168)
}
if [ $phyDrives -eq 2 ] ; then
	OS	
elif [ $phyDrives -eq 3 ] ; then
	OS	
	$($GHS)
elif [ $phyDrives -eq 4 ] ; then
	OS
	$($APP0)
	$($GHS)
elif [ $phyDrives -eq 5 ] ; then
	OS
	$($APP1)
	$($GHS)
elif [ $phyDrives -gt 5 ] ; then
	OS
	$($APP5)
	$($GHS)
else
	OS
fi
$($mod)
