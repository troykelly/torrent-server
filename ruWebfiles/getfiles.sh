#!/usr/bin/env sh

cd /app
git init
git remote add origin ${RUREPO}
git fetch origin
git checkout -b master --track origin/master # origin/master is clone's default
git reset origin/master
chown -R ${APP_USER}:${APP_GROUP} /app
chown -R ${APP_USER}:${APP_GROUP} /torrents
chown -R ${APP_USER}:${APP_GROUP} /security
mkdir -p /security/caddy
touch /security/caddy/users
find /app -type d -exec chmod 775 "{}" \;
find /app -type f -exec chmod 664 "{}" \;
find /app -type f -name "*.sh" -exec chmod 775 "{}" \;
find /torrents -type d -exec chmod 775 "{}" \;
find /torrents -type f -exec chmod 664 "{}" \;
find /security -type d -exec chmod 775 "{}" \;
find /security -type f -exec chmod 664 "{}" \;
