#!/usr/bin/env bash
scriptVersion="1.0.000"

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
  echo $m_time" :: AutoExtras :: "$1
}

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/AutoExtras.txt" ]; then
	find /config/logs -type f -name "AutoExtras.txt" -size +1024k -delete
fi

exec &>> "/config/logs/AutoExtras.txt"
chmod 666 "/config/logs/AutoExtras.txt"

radarrMovieList=$(curl -s --header "X-Api-Key:"${arrApiKey} --request GET  "$arrUrl/api/v3/movie")
radarrMovieTotal=$(echo "${radarrMovieList}"  | jq -r '.[] | select(.hasFile==true) | .id' | wc -l)
radarrMovieIds=$(echo "${radarrMovieList}" | jq -r '.[] | select(.hasFile==true) | .id')

loopCount=0
for id in $(echo $radarrMovieIds); do
    loopCount=$(( $loopCount + 1 ))
    log "$loopCount of $radarrMovieTotal :: $id :: Processing with MovieExtras.bash"
    bash /config/extended/scripts/MovieExtras.bash "$id"
done

exit
