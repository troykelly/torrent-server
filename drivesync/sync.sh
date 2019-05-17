#!/usr/bin/env sh

RSYNCCONF="${HOME}/.config/rclone/rclone.conf"
RCLONE=$(command -v rclone)

RSYNCCONFFOLDER=$(dirname ${RSYNCCONF})
RSYNCCONFFILE=$(basename ${RSYNCCONF})

if [ ! -f ${RSYNCCONF} ]; then
  mkdir -p ${RSYNCCONFFOLDER}
  cat<<EOF>${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
[google-drive]
type = drive
client_id = ${GOOGLE_CLIENTID}
client_secret = ${GOOGLE_CLIENTSECRET}
scope = drive
root_folder_id = ${DRIVE_ROOTFOLDER}
skip_gdocs = true
token = {"access_token":"${DRIVE_ACCESSTOKEN}","token_type":"Bearer","refresh_token":"${DRIVE_REFRESHTOKEN}","expiry":"${DRIVE_TOKENEXPIRY}"}
EOF
fi

RCLONECMD="${RCLONE} move --delete-after -v --stats 60s /upload google-drive:${DRIVE_TARGETFOLDER}"
while :
do
  nice -n 20 $RCLONECMD
  echo "Finished..."
  sleep 1800
done
