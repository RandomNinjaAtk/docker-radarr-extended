#!/usr/bin/env bash
scriptVersion="1.0.001"

if [ -z "$arrUrl" ] || [ -z "$arrApiKey" ]; then
	arrUrlBase="$(cat /config/config.xml | xq | jq -r .Config.UrlBase)"
	if [ "$arrUrlBase" = "null" ]; then
		arrUrlBase=""
	else
		arrUrlBase="/$(echo "$arrUrlBase" | sed "s/\///g")"
	fi
	arrApiKey="$(cat /config/config.xml | xq | jq -r .Config.ApiKey)"
	arrUrl="http://127.0.0.1:7878${arrUrlBase}"
fi

# Configure Yaml with URL and API Key
sed -i "s%arrUrl%$arrUrl%g" "/recyclarr.yaml"
sed -i "s%arrApi%$arrApiKey%g" "/recyclarr.yaml"

if [ ! -f /config/extended/configs/recyclarr.yaml ]; then
	cp "/recyclarr.yaml" "/config/extended/configs/recyclarr.yaml"
	chmod 766 "/config/extended/configs/recyclarr.yaml"
	chown abc:abc "/config/extended/configs/recyclarr.yaml"
fi

# update radarr
/recyclarr/recyclarr radarr -c /config/extended/configs/recyclarr.yaml --app-data /recylarr

exit
