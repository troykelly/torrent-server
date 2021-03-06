#!/usr/bin/env sh

RSYNCCONF="${HOME}/.config/rclone/rclone.conf"
RCLONE=$(command -v rclone)

RSYNCCONFFOLDER=$(dirname ${RSYNCCONF})
RSYNCCONFFILE=$(basename ${RSYNCCONF})

if [ ! -f ${RSYNCCONF} ]; then
  mkdir -p ${RSYNCCONFFOLDER}
  cat<<EOF>${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
[gdrive]
type = drive
client_id = ${GOOGLE_CLIENT_ID}
client_secret = ${GOOGLE_CLIENT_SECRET}
scope = drive
root_folder_id = ${DRIVE_ROOTFOLDER}
use_trash = false
skip_gdocs = true
chunk_size = 32M
token = {"access_token":"${DRIVE_ACCESSTOKEN}","token_type":"Bearer","refresh_token":"${DRIVE_REFRESHTOKEN}","expiry":"${DRIVE_TOKENEXPIRY}"}
team_drive = ${DRIVE_ROOTFOLDER}

[gcache]
type = cache
remote = gdrive:/gdrive
plex_url = ${PLEX_URL}
plex_username = ${PLEX_USERNAME}
plex_password = ${PLEX_PASSWORD}
chunk_size = 10M
info_age = 1h0m0s
chunk_total_size = 10G
plex_token = ${PLEX_TOKEN}

[gcrypt]
type = crypt
remote = gcache:/crypt
filename_encryption = standard
directory_name_encryption = true
password = ${GCRYPT_PASSWORD}
password2 = ${GCRYPT_PASSWORD2}
EOF
fi

RCLONECMD="${RCLONE} move --delete-after -v --stats 60s /upload google-drive:${DRIVE_TARGETFOLDER}"
while :
do
  nice -n 20 $RCLONECMD
  echo "Finished..."
  sleep 1800
done
