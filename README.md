# [RandomNinjaAtk/radarr-extended](https://github.com/RandomNinjaAtk/docker-radarr-extended)
[![Docker Build](https://img.shields.io/docker/cloud/automated/randomninjaatk/radarr-extended?style=flat-square)](https://hub.docker.com/r/randomninjaatk/radarr-extended)
[![Docker Pulls](https://img.shields.io/docker/pulls/randomninjaatk/radarr-extended?style=flat-square)](https://hub.docker.com/r/randomninjaatk/radarr-extended)
[![Docker Stars](https://img.shields.io/docker/stars/randomninjaatk/radarr-extended?style=flat-square)](https://hub.docker.com/r/randomninjaatk/radarr-extended)
[![Docker Hub](https://img.shields.io/badge/Open%20On-DockerHub-blue?style=flat-square)](https://hub.docker.com/r/randomninjaatk/radarr-extended)

[Radarr](https://github.com/Radarr/Radarr) - A fork of Sonarr to work with movies à la Couchpotato.


[![radarr](https://raw.githubusercontent.com/RandomNinjaAtk/unraid-templates/master/randomninjaatk/img/radarr.png)](https://github.com/Radarr/Radarr)

This containers base image is provided by: [linuxserver/radarr](https://github.com/linuxserver/docker-radarr)


## Features
* Downloading **Movie Trailers** and **Extras** using online sources for use in popular applications (Plex/Kodi/Emby/Jellyfin): 
  * Connects to Radarr to automatically download trailers for Movies in your existing library
  * Downloads videos using yt-dlp automatically
  * Names videos correctly to match Plex/Emby naming convention (Emby not tested)
  * Embeds relevant metadata into each video
  
### Plex Example
![](https://raw.githubusercontent.com/RandomNinjaAtk/docker-amtd/master/.github/amvtd-plex-example.jpg)


## Supported Architectures

The architectures supported by this image are:

| Architecture | Available | Tag |
| :----: | :----: | ---- |
| multi | ✅ | latest |
| x86-64 | ✅ | amd64 |
| arm64v8 | ✅ | arm64v8 |
| arm32v7 | ✅ | arm32v7 |

## Version Tags

| Tag | Description |
| :----: | --- |
| develop | Radarr (develop) + Extended Scripts |

## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| ---- | --- |
| `-p 7878` | The port for the Radarr webinterface |
| `-v /config` | Database and Radarr configs |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=America/New_York` | Specify a timezone to use EG Europe/London, this is required for Radarr |
| `-e UMASK_SET=022` | control permissions of files and directories created by Radarr |
| `-e enableAutoConfig=true` | true = enabled :: Enables AutoConfig script to run after startup |
| `-e enableRecyclarr=true` | true = enabled :: Enables Recyclarr to run every 4 hours |
| `-e enableQueueCleaner=true` | true = enabled :: Enables QueueCleaner Script that automatically removes stuck downloads that cannot be automatically imported on a 15 minute interval |
| `-e enableExtras=true` | true = enabled :: Enables MovieExtras script to run during download import process |
| `-e extrasType=all` | all or trailers :: all downloads all available videos (trailers, clips, featurette, etc...) :: trailers only downloads trailers |
| `-e extrasLanguages=en` | Set the primary desired language, if not found, fallback to next langauge in the list... (this is a "," separated list of ISO 639-1 language codes) |
| `-e extrasOfficialOnly=true` | true = enabled :: Skips extras that are not considered/marked as Official from TMDB site. |
| `-e extrasSingle=false` | true = enabled :: Only downloads the first available trailer, does not download any other extras |
| `-e extrasKodiCompatibility=false` | true = enabled :: Only works if "extrasSingle" is set to true, names trailer in a kodi compatible naming scheme (movie-trailer.mkv) |
| `-e plexUrl=http://x.x.x.x:32400` | ONLY used if PlexNotify.bash is used...|
| `-e plexToken=` | ONLY used if PlexNotify.bash is used... |

## Application Setup

Access the webui at `<your-ip>:7878`, for more information check out [Radarr](https://radarr.video/).
