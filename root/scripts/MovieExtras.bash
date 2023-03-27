#!/usr/bin/env bash
scriptVersion="1.0.1"
arrEventType="$radarr_eventtype"
arrItemId=$radarr_movie_id
tmdbApiKey="3b7751e3179f796565d88fdb2fcdf426"
autoScan="false"
updatePlex="false"

if [ ! -z "$1" ]; then
    arrItemId="$1"
    autoScan="true"
else
    autoScan="false"
fi

# Debugging
#arrItemId=1
#extrasLanguages=it-IT,en-US
#extrasType=all
#extrasOfficialOnly=false
#extrasKodiCompatibility=true
#extrasSingle=false
#enableExtras=true

if [ -z "$arrUrl" ] || [ -z "$arrApiKey" ]; then
  arrUrlBase="$(cat /config/config.xml | xq | jq -r .Config.UrlBase)"
  if [ "$arrUrlBase" == "null" ]; then
    arrUrlBase=""
  else
    arrUrlBase="/$(echo "$arrUrlBase" | sed "s/\///g")"
  fi
  arrApiKey="$(cat /config/config.xml | xq | jq -r .Config.ApiKey)"
  arrPort="$(cat /config/config.xml | xq | jq -r .Config.Port)"
  arrUrl="http://127.0.0.1:${arrPort}${arrUrlBase}"
fi

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/MovieExtras.txt" ]; then
	find /config/logs -type f -name "MovieExtras.txt" -size +1024k -delete
fi

if [ ! -f "/config/logs/MovieExtras.txt" ]; then
    touch "/config/logs/MovieExtras.txt"
    chmod 777 "/config/logs/MovieExtras.txt"
fi
exec &> >(tee -a "/config/logs/MovieExtras.txt")

log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: MovieExtras :: $scriptVersion :: "$1
}

if [ "$arrEventType" == "Test" ]; then
	log "Tested Successfully"
	exit 0	
fi

if [ "$enableExtras" != "true" ]; then
    log "Script disabled, exiting..."
    log "Enable by setting enableExtras=true"
    exit
fi

if [ "$autoScan" == "true" ]; then
    if [ ! -z "$2" ]; then
    	cookiesFile="$2"
    else
       cookiesFile=""
    fi    
else
    if find /config -type f -iname "cookies.txt" | read; then
        cookiesFile="$(find /config -type f -iname "cookies.txt" | head -n1)"
        log "Cookies File Found!"
    else
        log "Cookies File Not Found!"
        cookiesFile=""
    fi
fi

arrItemData=$(curl -s "$arrUrl/api/v3/movie/$arrItemId?apikey=$arrApiKey")
itemTitle=$(echo "$arrItemData" | jq -r .title)
itemHasFile=$(echo "$arrItemData" | jq -r .hasFile)
itemPath="$(echo "$arrItemData" | jq -r ".path")"
itemFileName=$(curl -s "$arrUrl/api/v3/moviefile?movieId=$arrItemId&apikey=$arrApiKey" | jq -r .[].relativePath)
itemFileNameNoExt="${itemFileName%.*}"
itemFolder="$(basename "$itemPath")"
itemRelativePath="$(echo "$arrItemData" | jq -r ".movieFile.relativePath")"
itemTrailerId="$(echo "$arrItemData" | jq -r ".youTubeTrailerId")"
tmdbId="$(echo "$arrItemData" | jq -r ".tmdbId")"



if [ ! -d "$itemPath" ]; then
    log "$itemTitle :: ERROR: Item Path does not exist ($itemPath), Skipping..."
    exit
fi

if [ "$extrasSingle" == "true" ]; then
    extrasType="trailer"
fi

IFS=',' read -r -a filters <<< "$extrasLanguages"
for filter in "${filters[@]}"
do
    if [ "$useProxy" != "true" ] ; then
    	tmdbVideosListData=$(curl -s "https://api.themoviedb.org/3/movie/$tmdbId/videos?api_key=$tmdbApiKey&language=$filter" | jq -r '.results[] | select(.site=="YouTube")')
    else 
        tmdbVideosListData=$(curl -x $proxyUrl:$proxyPort --proxy-user $proxyUsername:$proxyPassword -s "https://api.themoviedb.org/3/movie/$tmdbId/videos?api_key=$tmdbApiKey&language=$filter" | jq -r '.results[] | select(.site=="YouTube")')
    fi
    tmdbVideosListData=$(curl -s "https://api.themoviedb.org/3/movie/$tmdbId/videos?api_key=$tmdbApiKey&language=$filter" | jq -r '.results[] | select(.site=="YouTube")')
    log "$itemTitle :: Searching for \"$filter\" extras..."
    if [ "$extrasType" == "all" ]; then
        tmdbVideosListDataIds=$(echo "$tmdbVideosListData" | jq -r ".id")
        tmdbVideosListDataIdsCount=$(echo "$tmdbVideosListData" | jq -r ".id" | wc -l)
    else
        tmdbVideosListDataIds=$(echo "$tmdbVideosListData" | jq -r "select(.type==\"Trailer\") | .id")
        tmdbVideosListDataIdsCount=$(echo "$tmdbVideosListData" | jq -r "select(.type==\"Trailer\") | .id" | wc -l)
    fi
    if [ -z "$tmdbVideosListDataIds" ]; then
        log "$itemTitle :: None found..."
        continue
    fi

    if [ $tmdbVideosListDataIdsCount -le 0 ]; then
        log "$itemTitle :: No Extras Found, skipping..."
        exit
    fi

    log "$itemTitle :: $tmdbVideosListDataIdsCount Extras Found!"

    i=0
    for id in $(echo "$tmdbVideosListDataIds"); do
        i=$(( i + 1))
        tmdbExtraData="$(echo "$tmdbVideosListData" | jq -r "select(.id==\"$id\")")"
        tmdbExtraTitle="$(echo "$tmdbExtraData" | jq -r .name)"
        tmdbExtraTitleClean="$(echo "$tmdbExtraTitle" | sed -e "s/[^[:alpha:][:digit:]$^&_+=()'%;{},.@#]/ /g" -e "s/  */ /g" | sed 's/^[.]*//' | sed  's/[.]*$//g' | sed  's/^ *//g' | sed 's/ *$//g')"
        tmdbExtraKey="$(echo "$tmdbExtraData" | jq -r .key)"
        tmdbExtraType="$(echo "$tmdbExtraData" | jq -r .type)"
        tmdbExtraOfficial="$(echo "$tmdbExtraData" | jq -r .official)"

        if [ "$tmdbExtraOfficial" != "true" ]; then
            if [ "$extrasOfficialOnly" == "true" ]; then
                log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: Not official, skipping..."
                continue
            fi
        fi

        if [ "$tmdbExtraType" == "Featurette" ]; then
            extraFolderName="featurettes"
        elif [ "$tmdbExtraType" == "Trailer" ]; then
            extraFolderName="trailers"
        elif [ "$tmdbExtraType" == "Behind the Scenes" ]; then
            extraFolderName="behind the scenes"
        else
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: ERROR :: Extra Type Not found"
            if [ -f "/config/logs/MovieExtras-InvalidType.txt" ]; then
                if cat "/config/logs/MovieExtras-InvalidType.txt" | grep "$tmdbExtraType" | read; then
                    continue
                else
                    echo "$tmdbExtraType" >> "/config/logs/MovieExtras-InvalidType.txt"
                fi
            fi
            echo "$tmdbExtraType" >> "/config/logs/MovieExtras-InvalidType.txt"
            continue
        fi
        
        if [ "$extrasSingle" == "true" ]; then
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: Single Trailer Enabled..."
            if [ "$extrasKodiCompatibility" == "true" ] ; then
                finalPath="$itemPath"
                finalFileName="$itemFileNameNoExt-trailer"
            else
                finalPath="$itemPath/$extraFolderName"
		if [ -f "$finalPath/$tmdbExtraTitleClean.mkv" ]; then 
			rm "$finalPath/$tmdbExtraTitleClean.mkv"
		fi
		finalFileName="$itemFolder"
            fi
        else
            finalPath="$itemPath/$extraFolderName"
            finalFileName="$tmdbExtraTitleClean"
        fi

        if [ ! -d "$finalPath" ]; then
            mkdir -p "$finalPath"
            chmod 777 "$finalPath"
        fi


        if [ -f "$finalPath/$finalFileName.mkv" ]; then
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: Already Downloaded, skipping..."
            if [ "$extrasSingle" == "true" ]; then
                log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: Finished processing single trailer download" 
                break
            fi
            continue
        elif [ -f "$finalPath/movie-trailer.mkv" ]; then 
            if [ "$extrasKodiCompatibility" == "true" ] ; then
                log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: Removing old \"movie-trailer.mkv\" to replace with Kodi naming..."
                rm "$finalPath/movie-trailer.mkv"
            fi
        fi

        videoLanguages="$(echo "$extrasLanguages" | sed "s/-[[:alpha:]][[:alpha:]]//g")"

        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: Downloading (yt-dlp :: $videoFormat)..."
        if [ ! -z "$cookiesFile" ]; then
            yt-dlp -f "$videoFormat" --no-video-multistreams --cookies "$cookiesFile" -o "$finalPath/$finalFileName" --write-sub --sub-lang $videoLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$tmdbExtraKey"
        else
            yt-dlp -f "$videoFormat" --no-video-multistreams -o "$finalPath/$finalFileName" --write-sub --sub-lang $videoLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$tmdbExtraKey"
        fi
        if [ -f "$finalPath/$finalFileName.mkv" ]; then
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: Compete"
            chmod 666 "$finalPath/$finalFileName.mkv"
        else
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: ERROR :: Download Failed"
            continue
        fi

        if python3 /usr/local/sma/manual.py --config "/sma.ini" -i "$finalPath/$finalFileName.mkv" -nt; then
            sleep 0.01
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle :: Processed with SMA..."
            rm  /usr/local/sma/config/*log*
        else
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle :: ERROR :: SMA Processing Error"
            rm "$finalPath/$finalFileName.mkv"
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle :: INFO: deleted: $finalPath/$finalFileName.mkv"
        fi

        updatePlex="true"

        if [ "$extrasSingle" == "true" ]; then
            log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: Finished processing single trailer download" 
            break
        fi
        
    done

done

# Process item with PlexNotify.bash if plexToken is configured
if [ ! -z "$plexToken" ]; then
    # Always update plex if extra is downloaded
    if [ "$updatePlex" == "true" ]; then
        log "Using PlexNotify.bash to update Plex...."
        bash /config/extended/scripts/PlexNotify.bash "$itemPath"
        exit
    fi
    
    # Do not notify plex if this script was triggered by the AutoExtras.bash and no Extras were downloaded
    if [ "$autoScan" == "true" ]; then 
        log "Skipping plex notification, not needed...."
        exit
    else
        log "Using PlexNotify.bash to update Plex...."
        bash /config/extended/scripts/PlexNotify.bash "$itemPath"
        exit
    fi
fi

exit
