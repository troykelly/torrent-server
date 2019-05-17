#!/usr/bin/env bash

docker kill $(docker ps -q)
docker rm $(docker ps -a -q)
yes | docker system prune -a
#rm -Rf ./logs ./security ./public_html ./torrents
