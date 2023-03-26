#!/usr/bin/env bash
scriptVersion="1.0.2"
arrEventType="$radarr_eventtype"

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/SMA.txt" ]; then
	find /config/logs -type f -name "SMA.txt" -size +1024k -delete
fi

if [ ! -f "/config/logs/SMA.txt" ]; then
    touch "/config/logs/SMA.txt"
    chmod 777 "/config/logs/SMA.txt"
fi
exec &> >(tee -a "/config/logs/SMA.txt")

log () {
    m_time=`date "+%F %T"`
    echo $m_time" :: SMA :: $scriptVersion :: "$1
}

if [ "$arrEventType" == "Test" ]; then
	log "Tested Successfully"
	exit
fi

Extras () {
    if find /config -type f -iname "cookies.txt" | read; then
        cookiesFile="$(find /config -type f -iname "cookies.txt" | head -n1)"
        log "Cookies File Found!"
    else
        log "Cookies File Not Found!"
        cookiesFile=""
    fi
    # Extras Script
    bash /config/extended/scripts/MovieExtras.bash "$radarr_movie_id" "$cookiesFile"
}

NotifyPlex () {
    # Process item with PlexNotify.bash if plexToken is configured
    if [ ! -z "$plexToken" ]; then
        # update plex
        log "$itemTitle :: Using PlexNotify.bash to update Plex...."
        bash /config/extended/scripts/PlexNotify.bash "$radarr_movie_path"
    fi
}

ProcessWithSma () {
    log "Processing :: $radarr_moviefile_path"
    if python3 /usr/local/sma/manual.py --config "/config/extended/configs/sma.ini" -i "$radarr_moviefile_path" -tmdb $radarr_movie_tmdbid -a; then
        sleep 0.01
        log "COMPLETE!"
        rm  /usr/local/sma/config/*log*
    else
        log "ERROR :: SMA Processing Error"
    fi
}

ProcessWithSma
Extras
NotifyPlex

exit
