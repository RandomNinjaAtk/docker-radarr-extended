#!/usr/bin/env bash
scriptVersion="1.0.001"
arrEventType="$radarr_eventtype"
arrItemId=$radarr_movie_id
tmdbApiKey="3b7751e3179f796565d88fdb2fcdf426"

# Debugging
#arrItemId=11677
#trailerLanguages=en
#trailerExtrasType=all
#trailerOfficialOnly=true
#trailerSingle=true

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

if [ "$arrEventType" == "Test" ]; then
	log "Tested Successfully"
	exit 0	
fi

#exec &>> "/config/logs/MovieExtras.txt"
#chmod 666 "/config/logs/MovieExtras.txt"

log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: MovieExtras :: "$1
}

if find /config -type f -name "cookies.txt" | read; then
        cookiesFile="$(find /config -type f -iname "cookies.txt" | head -n1)"
        log "Cookies File Found!"
    else
        log "Cookies File Not Found!"
        cookiesFile=""
    fi

pip install yt-dlp --upgrade --no-cache-dir &>/dev/null
arrItemData=$(curl -s "$arrUrl/api/v3/movie/$arrItemId?apikey=$arrApiKey")
itemTitle=$(echo "$arrItemData" | jq -r .title)
itemHasFile=$(echo "$arrItemData" | jq -r .hasFile)
itemPath="$(echo "$arrItemData" | jq -r ".path")"
itemTrailerId="$(echo "$arrItemData" | jq -r ".youTubeTrailerId")"
tmdbId="$(echo "$arrItemData" | jq -r ".tmdbId")"

echo "$arrItemData"
echo "================"
echo $itemHasFile
echo "$itemPath"
echo "$itemTrailerId"
echo "$itemTrailerurl"
echo "$tmdbId"

if [ ! -d "$itemPath" ]; then
    log "$itemTitle :: ERROR: Item Path does not exist ($itemPath), Skipping..."
    exit
fi
if [ -z "$itemTrailerId" ]; then
    log "$itemTitle :: ERROR: No Trailer ID Found, Skipping..."
    exit
fi
tmdbVideosListData=$(curl -s "https://api.themoviedb.org/3/movie/$tmdbId/videos?api_key=$tmdbApiKey&language=jp" | jq -r '.results[] | select(.site=="YouTube")')
echo "$tmdbVideosListData"

if [ ! -f "$itemPath/Trailer-trailer.mkv" ]; then
    if [ ! -z "$cookiesFile" ]; then
        yt-dlp --cookies "$cookiesFile" -o "$itemPath/Trailer-trailer" --write-sub --sub-lang $trailerLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$itemTrailerId"
    else
        yt-dlp -o "$itemPath/Trailer-trailer" --write-sub --sub-lang $trailerLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$itemTrailerId"
    fi
fi

if [ "$trailerSingle" == "true" ]; then
    exit
fi


IFS=',' read -r -a filters <<< "$trailerLanguages"
for filter in "${filters[@]}"
do
	log "$itemTitle :: Searching for \"$filter\" extras..."
	tmdbVideosListData=$(curl -s "https://api.themoviedb.org/3/movie/$tmdbId/videos?api_key=$tmdbApiKey&language=$filter" | jq -r '.results[] | select(.site=="YouTube")')
	if [ "$trailerExtrasType" == "all" ]; then
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

echo "$tmdbVideosListDataIdsCount"

log "$itemTitle :: $tmdbVideosListDataIdsCount Extras Found!"
i=0
for id in $(echo "$tmdbVideosListDataIds"); do
    i=$(( i + 1))
    log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: Processing..."
    tmdbExtraData="$(echo "$tmdbVideosListData" | jq -r "select(.id==\"$id\")")"
    tmdbExtraTitle="$(echo "$tmdbExtraData" | jq -r .name)"
    tmdbExtraTitleClean="$(echo "$tmdbExtraTitle" | sed -e "s/[^[:alpha:][:digit:]$^&_+=()'%;{},.@#]/ /g" -e "s/  */ /g" | sed 's/^[.]*//' | sed  's/[.]*$//g' | sed  's/^ *//g' | sed 's/ *$//g')"
    tmdbExtraKey="$(echo "$tmdbExtraData" | jq -r .key)"
    tmdbExtraType="$(echo "$tmdbExtraData" | jq -r .type)"
    tmdbExtraOfficial="$(echo "$tmdbExtraData" | jq -r .official)"

    if [ "$trailerOfficialOnly" != "$tmdbExtraOfficial" ]; then
        log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: Not official, skipping..."
        continue
    fi

    if [ "$tmdbExtraType" == "Featurette" ]; then
        fileSuffix=featurette
	elif [ "$tmdbExtraType" == "Trailer" ]; then
        fileSuffix=trailer
	elif [ "$themoviedbvidetype" == "Behind the Scenes" ]; then
        fileSuffix=behindthescenes
	elif [ "$themoviedbvidetype" == "Clip" ]; then
        fileSuffix=clip
    elif [ "$themoviedbvidetype" == "Bloopers" ]; then
        fileSuffix=scene
    fi
    log "$itemTitle :: $i of $tmdbVideosListDataIdsCount :: $tmdbExtraType :: $tmdbExtraTitle ($tmdbExtraKey)"
    if [ ! -z "$cookiesFile" ]; then
        yt-dlp --cookies "$cookiesFile" -o "$itemPath/$tmdbExtraTitleClean-$fileSuffix" --write-sub --sub-lang $trailerLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$tmdbExtraKey"
    else
        yt-dlp -o "$itemPath/$tmdbExtraTitleClean-$fileSuffix" --write-sub --sub-lang $trailerLanguages --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "https://www.youtube.com/watch?v=$tmdbExtraKey"
    fi
    break
done
exit
