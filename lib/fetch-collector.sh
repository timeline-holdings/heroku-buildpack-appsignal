#!/usr/bin/env bash
set -e

echo "Building Docker image to fetch AppSignal collector..."
docker build -t appsignal-collector-fetcher -f Dockerfile.collector .

echo "Extracting collector binary..."
docker create --name collector-temp appsignal-collector-fetcher
docker cp collector-temp:/collector/appsignal-collector bin/appsignal-collector
docker rm collector-temp

chmod +x bin/appsignal-collector

echo "AppSignal collector binary has been extracted to bin/appsignal-collector"
echo "Don't forget to commit this binary to version control!"
