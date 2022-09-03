#!/usr/bin/env bash
version=1.0.001

notfidedBy="Radarr"
arrRootFolderPath="$(dirname "$radarr_movie_path")"
arrFolderPath="$radarr_movie_path"
arrEventType="$radarr_eventtype"
movieExtrasPath="$1"

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/PlexNotify.txt" ]; then
	find /config/logs -type f -name "PlexNotify.txt" -size +1024k -delete
fi

exec &>> "/config/logs/PlexNotify.txt"
chmod 666 "/config/logs/PlexNotify.txt"

log () {
    m_time=`date "+%F %T"`
    echo $m_time" :: PlexNotify :: "$1
}

if [ "$enableExtras" == "true" ]; then
    if [ -z "$movieExtrasPath" ]; then
		log "MovieExtras script is enabled, skipping..."
		exit
	fi
fi

if [ "$arrEventType" == "Test" ]; then
	log "$notfidedBy :: Tested Successfully"
	exit 0	
fi

# Validate connection
plexVersion=$(curl -s "$plexUrl/?X-Plex-Token=$plexToken" | xq . | jq -r '.MediaContainer."@version"')
if [ $plexVersion = null ]; then
	log "$notfidedBy :: ERROR :: Cannot communicate with Plex"
	log "$notfidedBy :: ERROR :: Please check your plexUrl and plexToken"
	log "$notfidedBy :: ERROR :: Configured plexUrl \"$plexUrl\""
	log "$notfidedBy :: ERROR :: Configured plexToken \"$plexToken\""
	log "$notfidedBy :: ERROR :: Exiting..."
	exit
else
	log "$notfidedBy :: Plex Connection Established, version: $plexVersion"
fi

plexLibraries="$(curl -s "$plexUrl/library/sections?X-Plex-Token=$plexToken")"
plexLibraryData=$(echo "$plexLibraries" | xq ".MediaContainer.Directory")
plexKeys=($(echo "$plexLibraries" | xq ".MediaContainer.Directory" | jq -r '."@key"'))

if echo "$plexLibraryData" | grep "\"@path\": \"$arrRootFolderPath" | read; then
	sleep 0.01
else
	log "$notfidedBy :: ERROR: No Plex Library found containing path \"$arrRootFolderPath\""
	log "$notfidedBy :: ERROR: Add \"$arrRootFolderPath\" as a folder to a Plex Movie Library"
	exit 1
fi

for key in ${!plexKeys[@]}; do
	plexKey="${plexKeys[$key]}"
	if echo "$plexLibraryData" | grep "\"@path\": \"$arrRootFolderPath" | read; then
		plexFolderEncoded="$(jq -R -r @uri <<<"$arrFolderPath")"
		curl -s "$plexUrl/library/sections/$plexKey/refresh?path=$plexFolderEncoded&X-Plex-Token=$plexToken"
		log  "$notfidedBy :: Plex Scan notification sent! ($arrFolderPath)"
	fi
done

exit 0
