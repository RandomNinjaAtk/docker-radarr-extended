FROM linuxserver/radarr:amd64-develop
LABEL maintainer="RandomNinjaAtk"

ENV SMA_PATH /usr/local/sma
ENV UPDATE_SMA FALSE
ENV SMA_APP Radarr
ENV videoFormat="bestvideo*+bestaudio/best"

RUN \
	echo "************ install packages ************" && \
	apk add -U --update --no-cache \
		flac \
		opus-tools \
		jq \
		git \
		wget \
		mkvtoolnix \
		python3-dev \
		libc-dev \
		py3-pip \
		gcc \
		ffmpeg \
		yt-dlp && \
	echo "************ install python packages ************" && \
	pip install --upgrade --no-cache-dir -U \
		excludarr \
		yq && \
	echo "************ setup SMA ************" && \
	echo "************ setup directory ************" && \
	mkdir -p ${SMA_PATH} && \
	echo "************ download repo ************" && \
	git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
	mkdir -p ${SMA_PATH}/config && \
	echo "************ create logging file ************" && \
	mkdir -p ${SMA_PATH}/config && \
	touch ${SMA_PATH}/config/sma.log && \
	chgrp users ${SMA_PATH}/config/sma.log && \
	chmod g+w ${SMA_PATH}/config/sma.log && \
	echo "************ install pip dependencies ************" && \
	python3 -m pip install --user --upgrade pip && \	
 	pip3 install -r ${SMA_PATH}/setup/requirements.txt && \
	echo "************ install recyclarr ************" && \
	mkdir -p /recyclarr && \
	wget "https://github.com/recyclarr/recyclarr/releases/latest/download/recyclarr-linux-musl-x64.zip" -O "/recyclarr/recyclarr.zip" && \
	unzip -o /recyclarr/recyclarr.zip -d /recyclarr &>/dev/null && \
	chmod 777 /recyclarr/recyclarr
	
# copy local files
COPY root/ /

# set working dir
WORKDIR /config

# ports and volumes
EXPOSE 7878
VOLUME /config
