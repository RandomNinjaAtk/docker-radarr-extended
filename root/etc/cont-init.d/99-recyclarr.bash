#!/usr/bin/with-contenv bash

echo "Setting up Recyclarr"

# Download Recyclarr
if [ ! -f /recyclarr/recyclarr ]; then
    mkdir -p /recyclarr
    wget -q "https://github.com/recyclarr/recyclarr/releases/latest/download/recyclarr-linux-musl-x64.zip" -O "/recyclarr/recyclarr.zip"
    unzip -o /recyclarr/recyclarr.zip -d /recyclarr &>/dev/null
    chmod u+rx /recyclarr/recyclarr
fi

echo "Complete"

exit $?
