#!/usr/bin/env bash
scriptVersion="1.0.003"

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
if [ -f "/config/logs/Recyclarr.txt" ]; then
	find /config/logs -type f -name "Recyclarr.txt" -size +1024k -delete
fi

touch "/config/logs/Recyclarr.txt"
exec &> >(tee -a "/config/logs/Recyclarr.txt")
chmod 666 "/config/logs/Recyclarr.txt"

log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: Recycalarr :: $scriptVersion :: "$1
}

# Configure Yaml with URL and API Key
sed -i "s%arrUrl%$arrUrl%g" "/recyclarr.yaml"
sed -i "s%arrApi%$arrApiKey%g" "/recyclarr.yaml"

if [ ! -f /config/extended/configs/recyclarr.yaml ]; then
	log "Importing default recylarr config file to: /config/extended/configs/recyclarr.yaml"
	cp "/recyclarr.yaml" "/config/extended/configs/recyclarr.yaml"
	chmod 777 "/config/extended/configs/recyclarr.yaml"
fi


# update radarr
log "Updating Radarr via Recyclarr"
/recyclarr/recyclarr radarr -c /config/extended/configs/recyclarr.yaml --app-data /recyclarr-data
log "Complete"

exit
