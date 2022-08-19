FROM alpine AS builder

# Download QEMU, see https://github.com/docker/hub-feedback/issues/1261
ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-arm.tar.gz
RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1

FROM linuxserver/radarr:arm32v7-develop

# Add QEMU
COPY --from=builder qemu-arm-static /usr/bin

LABEL maintainer="RandomNinjaAtk"

ENV SMA_PATH /usr/local/sma
ENV UPDATE_SMA FALSE
ENV SMA_APP Radarr

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
		ffmpeg && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
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
 	pip3 install -r ${SMA_PATH}/setup/requirements.txt
	
# copy local files
COPY root/ /

# set working dir
WORKDIR /config

# ports and volumes
EXPOSE 7878
VOLUME /config
