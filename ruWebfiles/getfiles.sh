#!/usr/bin/env bash

if [ -z "${RUTORRENT_APP_DIR}" ]; then
    RUTORRENT_APP_DIR="/app"
fi
if [ -z "${TORRENTS_DIR}" ]; then
    TORRENTS_DIR="/torrents"
fi
if [ -z "${SECURITY_DIR}" ]; then
    SECURITY_DIR="/security"
fi
if [ -z "${RUREPO}" ]; then
    RUREPO="https://github.com/Novik/ruTorrent.git"
fi
if [ -z "${APP_USER}" ]; then
    APP_USER="$(whoami)"
fi
if [ -z "${APP_GROUP}" ]; then
    APP_GROUP="$(id -g -n)"
fi

getRUTorrent ()
{
    echo "📁 Get ruTorrent"
    mkdir -p "${RUTORRENT_APP_DIR}" && \
        cd "${RUTORRENT_APP_DIR}" && \
        git init && \
        git config --global --add safe.directory /app && \
        git remote add origin "${RUREPO}" && \
        git fetch origin && \
        git checkout -b master --track origin/master && \
        git reset origin/master
}

updateRUTorrent ()
{
    echo "📂 Update ruTorrent"
    cd "${RUTORRENT_APP_DIR}"
    git config --global --add safe.directory /app
    git fetch --all
    git reset --hard origin/master
}

resetPermissions ()
{
    echo "🗄️ Scaffolding files"
    mkdir -p "${SECURITY_DIR}/caddy"
    mkdir -p "${TORRENTS_DIR}"
    touch "${SECURITY_DIR}/caddy/users"

    echo "🔒 Restting permissions to user ${APP_USER} and group ${APP_GROUP}"
    chown -R ${APP_USER}:${APP_GROUP} "${RUTORRENT_APP_DIR}"
    chown -R ${APP_USER}:${APP_GROUP} "${TORRENTS_DIR}"
    chown -R ${APP_USER}:${APP_GROUP} "${SECURITY_DIR}"
    find "${RUTORRENT_APP_DIR}" -type d -exec chmod 775 "{}" \;
    find "${RUTORRENT_APP_DIR}" -type f -exec chmod 664 "{}" \;
    find "${RUTORRENT_APP_DIR}" -type f -name "*.sh" -exec chmod 775 "{}" \;
    find "${TORRENTS_DIR}" -type d -exec chmod 775 "{}" \;
    find "${TORRENTS_DIR}" -type f -exec chmod 664 "{}" \;
    find "${SECURITY_DIR}" -type d -exec chmod 775 "{}" \;
    find "${SECURITY_DIR}" -type f -exec chmod 664 "{}" \;
}

if [ ! -f "${RUTORRENT_APP_DIR}/php/rtorrent.php" ]; then
    getRUTorrent
else
    updateRUTorrent
fi

resetPermissions
