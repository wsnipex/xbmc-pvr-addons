#!/bin/bash

if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]
then
	echo "usage $(basename $0) [distribution]"
	echo "default distribution: dist"
	exit 1
elif [[ $1 == "" ]]
then
	dist="dist"
else
	dist=$1
fi

declare -A PACKAGES=(
	["pvr.hts"]="xbmc-pvr-tvheadend-hts"
	["pvr.vuplus"]="xbmc-pvr-vuplus"
	["pvr.mediaportal.tvserver"]="xbmc-pvr-mediaportal-tvserver"
	["pvr.dvbviewer"]="xbmc-pvr-dvbviewer"
	["pvr.argustv"]="xbmc-pvr-argustv"
	["pvr.mythtv.cmyth"]="xbmc-pvr-mythtv-cmyth"
	["pvr.vdr.vnsi"]="xbmc-pvr-vdr-vnsi"
	["pvr.nextpvr"]="xbmc-pvr-nextpvr"
	["pvr.demo"]="xbmc-pvr-demo"
	["pvr.njoy"]="xbmc-pvr-njoy"
)

[[ $(basename $PWD) == "debian" ]] || cd debian

for package in "${!PACKAGES[@]}"
do
	echo "creating changelog for: $package"
	changelog="../addons/$package/addon/changelog.txt"
	addonxml="../addons/$package/addon/addon.xml.in"
	version=$(awk -F'=' '!/<?xml/ && /version/ && !/>/ {gsub("\"",""); print $2}' $addonxml)
	pvrapiversion=$(awk -F'=' '/import addon="xbmc.pvr"/ {gsub("\"",""); gsub("/>",""); print $3}' $addonxml)

	[[ -f ${PACKAGES["$package"]}.changelog ]] && mv ${PACKAGES["$package"]}.changelog ${PACKAGES["$package"]}.changelog.old

	echo "${version}-0${dist}~pvrapi${pvrapiversion}" > ${PACKAGES["$package"]}.version
	if [[ -f $changelog ]]
	then
		dch -c ${PACKAGES["$package"]}.changelog --create --empty --package xbmc-pvr-addons -v "${version}-0${dist}~pvrapi${pvrapiversion}" --distribution ${dist} --force-distribution 2>/dev/null $(cat $changelog | tail -80)
	else
		dch -c ${PACKAGES["$package"]}.changelog --create --empty --package xbmc-pvr-addons -v "${version}-0${dist}~pvrapi${pvrapiversion}" --distribution ${dist} --force-distribution 2>/dev/null "no upstream changelog available"
	fi
done

# special handling for vdr-pluging-vnsiserver
echo "creating changelog for: vdr-pluging-vnsiserver"
version="1:"$(awk -F'=' '/\*VERSION/ {gsub("\"",""); gsub(" ",""); gsub(";",""); print $2}' ../addons/pvr.vdr.vnsi/vdr-plugin-vnsiserver/vnsi.h)"-0${dist}"
echo "${version}" > vdr-plugin-vnsiserver.version

[[ -f "vdr-plugin-vnsiserver.changelog" ]] && mv vdr-plugin-vnsiserver.changelog vdr-plugin-vnsiserver.changelog.old
dch -c vdr-plugin-vnsiserver.changelog --create --empty --package xbmc-pvr-addons -v"${version}" --distribution ${dist} --force-distribution 2>&1 "no upstream changelog available"

exit 0


