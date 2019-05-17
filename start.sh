#!/usr/bin/env bash
docker-compose up -d
docker ps -a
docker logs -f torrentflux_tfwebfiles_1
#open -na "Google Chrome" --args --incognito "http://localhost:3000"
