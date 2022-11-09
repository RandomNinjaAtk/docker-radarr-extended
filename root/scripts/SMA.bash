#!/usr/bin/env bash
scriptVersion="1.0.0"
arrEventType="$radarr_eventtype"

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/SMA.txt" ]; then
	find /config/logs -type f -name "SMA.txt" -size +1024k -delete
fi

touch "/config/logs/SMA.txt"
chmod 666 "/config/logs/SMA.txt"
exec &> >(tee -a "/config/logs/SMA.txt")

log () {
    m_time=`date "+%F %T"`
    echo $m_time" :: SMA :: $scriptVersion :: "$1
}

if [ "$arrEventType" == "Test" ]; then
	log "Tested Successfully"
	exit
fi

log "Processing :: $radarr_moviefile_path"
if python3 /usr/local/sma/manual.py --config "/config/extended/configs/sma.ini" -i "$radarr_moviefile_path" -tmdb $radarr_movie_tmdbid -a; then
    sleep 0.01
    log "COMPLETE!"
    rm  /usr/local/sma/config/*log*
else
    log "ERROR :: SMA Processing Error"
fi

exit
