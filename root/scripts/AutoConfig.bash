#!/usr/bin/env bash
scriptVersion="1.0.001"

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
if [ -f "/config/logs/AutoConfig.txt" ]; then
	find /config/logs -type f -name "AutoConfig.txt" -size +1024k -delete
fi

exec &>> "/config/logs/AutoConfig.txt"
chmod 666 "/config/logs/AutoConfig.txt"

log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: AutoConfig :: "$1
}

log "Getting Trash Guide Recommended Movie Naming..."
movieNaming="$(curl -s https://raw.githubusercontent.com/TRaSH-/Guides/master/docs/Radarr/Radarr-recommended-naming-scheme.md | grep "{Movie Clean" | head -n 1)"

log "Updating Radarr Moving Naming..."
updateArr=$(curl -s "$arrUrl/api/v3/config/naming" -X PUT -H "Content-Type: application/json" -H "X-Api-Key: $arrApiKey" --data-raw "{
    \"renameMovies\":true,
    \"replaceIllegalCharacters\":true,
    \"colonReplacementFormat\":\"delete\",
    \"standardMovieFormat\":\"$movieNaming\",
    \"movieFolderFormat\":\"{Movie CleanTitle} ({Release Year})\",
    \"includeQuality\":false,
    \"replaceSpaces\":false,
    \"id\":1
    }")
    
log "Complete"
exit
