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

[[ $(basename $PWD) == "debian" ]] || cd debian
[[ -f versiontag ]] && tag=$(cat versiontag) || tag="0"
PVRAPI=$(awk '/XBMC_PVR_API_VERSION/ {gsub("\"",""); print $3 }' ../xbmc/xbmc_pvr_types.h)
echo "detected Xbmc PVR-API: $PVRAPI"

declare -A PACKAGES=(
	["pvr.hts"]="xbmc-pvr-tvheadend-hts${PVRAPI}"
	["pvr.vuplus"]="xbmc-pvr-vuplus${PVRAPI}"
	["pvr.mediaportal.tvserver"]="xbmc-pvr-mediaportal-tvserver${PVRAPI}"
	["pvr.dvbviewer"]="xbmc-pvr-dvbviewer${PVRAPI}"
	["pvr.argustv"]="xbmc-pvr-argustv${PVRAPI}"
	["pvr.mythtv.cmyth"]="xbmc-pvr-mythtv-cmyth${PVRAPI}"
	["pvr.vdr.vnsi"]="xbmc-pvr-vdr-vnsi${PVRAPI}"
	["pvr.nextpvr"]="xbmc-pvr-nextpvr${PVRAPI}"
	["pvr.demo"]="xbmc-pvr-demo${PVRAPI}"
	["pvr.njoy"]="xbmc-pvr-njoy${PVRAPI}"
)



for package in "${!PACKAGES[@]}"
do
	echo "creating changelog for: $package"
	changelog="../addons/$package/addon/changelog.txt"
	addonxml="../addons/$package/addon/addon.xml.in"
	aversion=$(awk -F'=' '!/<?xml/ && /version/ && !/>/ {gsub("\"",""); print $2}' $addonxml)
	pvrapiversion=$(awk -F'=' '/import addon="xbmc.pvr"/ {gsub("\"",""); gsub("/>",""); print $3}' $addonxml)

	[[ -f ${PACKAGES["$package"]}.changelog ]] && mv ${PACKAGES["$package"]}.changelog ${PACKAGES["$package"]}.changelog.old

	version="${aversion}-${tag}${dist}"
	echo "${version}" > ${PACKAGES["$package"]}.version
	if [[ -f $changelog ]]
	then
		dch -c ${PACKAGES["$package"]}.changelog --create --empty --package xbmc-pvr-addons${PVRAPI} -v "${version}" --distribution ${dist} --force-distribution 2>/dev/null $(cat $changelog | tail -80)
	else
		dch -c ${PACKAGES["$package"]}.changelog --create --empty --package xbmc-pvr-addons${PVRAPI} -v "${version}" --distribution ${dist} --force-distribution 2>/dev/null "no upstream changelog available"
	fi
	version=""
done

# special handling for vdr-pluging-vnsiserver
echo "creating changelog for: vdr-pluging-vnsiserver"
version="1:"$(awk -F'=' '/\*VERSION/ {gsub("\"",""); gsub(" ",""); gsub(";",""); print $2}' ../addons/pvr.vdr.vnsi/vdr-plugin-vnsiserver/vnsi.h)"-${tag}${dist}"
echo "${version}" > vdr-plugin-vnsiserver.version

[[ -f "vdr-plugin-vnsiserver.changelog" ]] && mv vdr-plugin-vnsiserver.changelog vdr-plugin-vnsiserver.changelog.old
dch -c vdr-plugin-vnsiserver.changelog --create --empty --package xbmc-pvr-addons${PVRAPI} -v"${version}" --distribution ${dist} --force-distribution 2>/dev/null "no upstream changelog available"

exit 0
