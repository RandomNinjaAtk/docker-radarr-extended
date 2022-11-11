FROM alpine AS builder

# Download QEMU, see https://github.com/docker/hub-feedback/issues/1261
ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-aarch64.tar.gz
RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1

FROM linuxserver/radarr:arm64v8-develop

# Add QEMU
COPY --from=builder qemu-aarch64-static /usr/bin

LABEL maintainer="RandomNinjaAtk"

ENV SMA_PATH /usr/local/sma
ENV UPDATE_SMA FALSE
ENV SMA_APP Radarr
ENV videoFormat="bestvideo*+bestaudio/best"

RUN \
	echo "************ install packages ************" && \
	apk add  -U --update --no-cache \
		flac \
		opus-tools \
		jq \
		git \
		wget \
		mkvtoolnix \
		python3 \
		py3-pip \
		yt-dlp \
		ffmpeg && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
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
	wget "https://github.com/recyclarr/recyclarr/releases/latest/download/recyclarr-linux-musl-arm64.zip" -O "/recyclarr/recyclarr.zip" && \
	unzip -o /recyclarr/recyclarr.zip -d /recyclarr &>/dev/null && \
	chmod 777 /recyclarr/recyclarr
	
# copy local files
COPY root/ /

# set working dir
WORKDIR /config

# ports and volumes
EXPOSE 7878
VOLUME /config
