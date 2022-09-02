#!/usr/bin/env bash
scriptVersion="1.0.002"

if [ -z "$arrUrl" ] || [ -z "$arrApiKey" ]; then
  arrUrlBase="$(cat /config/config.xml | xq | jq -r .Config.UrlBase)"
  if [ "$arrUrlBase" = "null" ]; then
    arrlBase=""
  else
    arrUrlBase="/$(echo "$arrUrlBase" | sed "s/\///g")"
  fi
  arrApiKey="$(cat /config/config.xml | xq | jq -r .Config.ApiKey)"
  arrPort="$(cat /config/config.xml | xq | jq -r .Config.Port)"
  arrUrl="http://127.0.0.1:${arrPort}${arrUrlBase}"
fi

# auto-clean up log file to reduce space usage
if [ -f "/config/logs/QueueCleaner.txt" ]; then
	find /config/logs -type f -name "QueueCleaner.txt" -size +1024k -delete
fi

exec &>> "/config/logs/QueueCleaner.txt"
chmod 666 "/config/logs/QueueCleaner.txt"

log () {
  m_time=`date "+%F %T"`
  echo $m_time" :: "$1
}

arrQueueData="$(curl -s "$arrUrl/api/v3/queue?page=1&pagesize=1000000000&sortDirection=descending&sortKey=progress&includeUnknownMovieItems=true&apikey=${arrApiKey}" | jq -r .records[])"
arrQueueIds=$(echo "$arrQueueData" | jq -r 'select(.status=="completed") | select(.trackedDownloadStatus=="warning") | .id')
for queueId in $(echo $arrQueueIds); do
  arrQueueItemData="$(echo "$arrQueueData" | jq -r "select(.id==$queueId)")"
  arrQueueItemTitle="$(echo "$arrQueueItemData" | jq -r .title)"
  log "Removing Failed Queue ID: $queueId ($arrQueueItemTitle) from Radarr Queue..."
  curl -sX DELETE "$arrUrl/api/v3/queue/$queueId?removeFromClient=true&blocklist=true&apikey=${arrApiKey}"
done

exit
