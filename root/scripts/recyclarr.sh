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

# recyclarrURL="$(curl -s "https://github.com/recyclarr/recyclarr/releases" | grep "recyclarr-linux-x64.zip" | head -n 1 |  grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | sed 's%/recyclarr/recyclarr%https://github.com/recyclarr/recyclarr%g')"

# Configure Yaml with URL and API Key
sed -i "s%arrUrl%$arrUrl%g" "/recyclarr.yaml"
sed -i "s%arrApi%$arrApiKey%g" "/recyclarr.yaml"

if [ ! -f /recyclarr/recyclarr ]; then
    mkdir -p /recyclarr
    wget -q "https://github.com/recyclarr/recyclarr/releases/latest/download/recyclarr-linux-musl-x64.zip" -O "/recyclarr/recyclarr.zip"
    unzip -o /recyclarr/recyclarr.zip -d /recyclarr &>/dev/null
    chmod u+rx /recyclarr/recyclarr
fi

if [ ! -f /config/extended/configs/recyclarr/recyclarr.yaml ]; then
	cp "/recyclarr.yaml" "/config/extended/configs/recyclarr/recyclarr.yaml"
	chmod 766 "/config/extended/configs/recyclarr/recyclarr.yaml"
	chown abc:abc "/config/extended/configs/recyclarr/recyclarr.yaml"
fi

# update radarr
/recyclarr/recyclarr radarr -c /config/extended/configs/recyclarr/recyclarr.yaml --app-data /recylarr
exit
