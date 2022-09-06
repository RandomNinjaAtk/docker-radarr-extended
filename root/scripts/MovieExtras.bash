#!/usr/bin/env bash
scriptVersion="1.0.007"
arrEventType="$radarr_eventtype"
arrItemId=$radarr_movie_id
tmdbApiKey="3b7751e3179f796565d88fdb2fcdf426"

if [ ! -z "$1" ]; then
    arrItemId=$1
fi

# Debugging
#arrItemId=11677
#extrasLanguages=en
#extrasType=all
#extrasOfficialOnly=true
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

log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: MovieExtras :: "$1
}

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/MovieExtras.txt" ]; then
	find /config/logs -type f -name "MovieExtras.txt" -size +1024k -delete
fi

if [ "$arrEventType" == "Test" ]; then
	log "Tested Successfully"
	exit 0	
fi

exec &>> "/config/logs/MovieExtras.txt"
chmod 666 "/config/logs/MovieExtras.txt"

if [ "$enableExtras" != "true" ]; then
    log "Script disabled, exiting..."
    log "Enable by setting enableExtras=true"
    exit
fi

if find /config -type f -name "cookies.txt" | read; then
    cookiesFile="$(find /config -type f -iname "cookies.txt" | head -n1)"
    log "Cookies File Found!"
else
    log "Cookies File Not Found!"
    cookiesFile=""
fi

arrItemData=$(curl -s "$arrUrl/api/v3/movie/$arrItemId?apikey=$arrApiKey")
itemTitle=$(echo "$arrItemData" | jq -r .title)
itemHasFile=$(echo "$arrItemData" | jq -r .hasFile)
itemPath="$(echo "$arrItemData" | jq -r ".path")"
itemRelativePath="$(echo "$arrItemData" | jq -r ".movieFile.relativePath")"
itemTrailerId="$(echo "$arrItemData" | jq -r ".youTubeTrailerId")"
tmdbId="$(echo "$arrItemData" | jq -r ".tmdbId")"


if [ ! -d "$itemPath" ]; then
    log "$itemTitle :: ERROR: Item Path does not exist ($itemPath), Skipping..."
    exit
fi

if [ "$extrasSingle" == "true" ]; then
    if [ "$extrasKodiCompatibility" == "true" ] ; then
        extrasFileName="movie-trailer"
    else
        extrasFileName="trailers/Trailer"
    fi

    if [ ! -z "$itemTrailerId" ]; then
        if [ ! -f "$itemPath/$extrasFileName.mkv" ]; then
		log "$itemTitle :: Trailer :: Downloading Trailer ($itemTrailerId)..."
            if [ ! -z "$cookiesFile" ]; then
                yt-dlp --cookies "$cookiesFile" -o "$itemPath/$extrasFileName" --write-sub --sub-lang $extrasLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$itemTrailerId"
            else
                yt-dlp -o "$itemPath/$extrasFileName" --write-sub --sub-lang $extrasLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$itemTrailerId"
            fi
        
	
		if python3 /usr/local/sma/manual.py --config "/sma.ini" -i "$itemPath/$extrasFileName.mkv" -nt &>/dev/null; then
			sleep 0.01
			log "$itemTitle :: Trailer :: Processed with SMA..."
			rm  /usr/local/sma/config/*log*
		else
			log "$itemTitle :: Trailer :: ERROR :: SMA Processing Error"
			rm "$itemPath/$extrasFileName.mkv" 
			log "$itemTitle :: Trailer :: INFO: deleted: $itemPath/$extrasFileName.mkv"
		fi
		if [ -f "$itemPath/$extrasFileName.mkv" ]; then
		    chmod 666 "$itemPath/$extrasFileName.mkv"
		    chown abc:abc "$itemPath/$extrasFileName.mkv"
		fi
    	else
		log "$itemTitle :: Trailer :: Already downloaded..."
	    fi
    else
        log "$itemTitle :: Trailer :: ERROR :: No Trailer ID Found, Skipping..."
    fi
    exit
fi

tmdbVideosListData=$(curl -s "https://api.themoviedb.org/3/movie/$tmdbId/videos?api_key=$tmdbApiKey" | jq -r '.results[] | select(.site=="YouTube")')

IFS=',' read -r -a filters <<< "$extrasLanguages"
for filter in "${filters[@]}"
do
    log "$itemTitle :: Searching for \"$filter\" extras..."
    if [ "$extrasType" == "all" ]; then
        tmdbVideosListDataIds=$(echo "$tmdbVideosListData" | jq -r "select(.iso_639_1==\"$filter\") | .id")
        tmdbVideosListDataIdsCount=$(echo "$tmdbVideosListData" | jq -r "select(.iso_639_1==\"$filter\") | .id" | wc -l)
    else
        tmdbVideosListDataIds=$(echo "$tmdbVideosListData" | jq -r "select(.iso_639_1==\"$filter\" and .type==\"Trailer\") | .id")
        tmdbVideosListDataIdsCount=$(echo "$tmdbVideosListData" | jq -r "select(.iso_639_1==\"$filter\" and .type==\"Trailer\") | .id" | wc -l)
    fi
    if [ -z "$tmdbVideosListDataIds" ]; then
        log "$itemTitle :: None found..."
        continue
    else
        break
    fi
done

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

    if [ ! -d "$itemPath/$extraFolderName" ]; then
        mkdir -p "$itemPath/$extraFolderName"
        chmod 777 "$itemPath/$extraFolderName"
        chown abc:abc "$itemPath/$extraFolderName"
    fi

    finalPath="$itemPath/$extraFolderName"

    if [ -f "$finalPath/$tmdbExtraTitleClean.mkv" ]; then
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: Already Downloaded, skipping..."
        continue
    fi

    log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: Downloading..."
    if [ ! -z "$cookiesFile" ]; then
        yt-dlp --cookies "$cookiesFile" -o "$finalPath/$tmdbExtraTitleClean" --write-sub --sub-lang $extrasLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$tmdbExtraKey" &>/dev/null
    else
        yt-dlp -o "$finalPath/$tmdbExtraTitleClean" --write-sub --sub-lang $extrasLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$tmdbExtraKey" &>/dev/null
    fi
    if [ -f "$finalPath/$tmdbExtraTitleClean.mkv" ]; then
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: Compete"
        chmod 666 "$finalPath/$tmdbExtraTitleClean.mkv"
        chown abc:abc "$finalPath/$tmdbExtraTitleClean.mkv"
    else
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey) :: ERROR :: Download Failed"
        continue
    fi

    if python3 /usr/local/sma/manual.py --config "/sma.ini" -i "$finalPath/$tmdbExtraTitleClean.mkv" -nt &>/dev/null; then
        sleep 0.01
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle :: Processed with SMA..."
        rm  /usr/local/sma/config/*log*
    else
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle :: ERROR :: SMA Processing Error"
        rm "$finalPath/$tmdbExtraTitleClean.mkv"
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle :: INFO: deleted: $finalPath/$tmdbExtraTitleClean.mkv"
    fi
    
done

# Process item with PlexNotify.bash if plexToken is configured
if [ ! -z "$plexToken" ]; then
    log "Using PlexNotify.bash to update Plex...."
    bash /config/extended/scripts/PlexNotify.bash "$itemPath"
fi

exit
