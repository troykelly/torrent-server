FROM alpine

ARG APP_USER
ARG APP_GROUP


RUN apk add --no-cache --update curl unzip

RUN cd ~ && \
 curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
 unzip rclone-current-linux-amd64.zip && \
 cd rclone-*-linux-amd64 && \
 cp rclone /usr/bin/ && \
 chmod 755 /usr/bin/rclone && \
 cd ~ && \
 rm -Rf ./rclone*

COPY sync.sh /usr/sbin/
RUN chmod +x /usr/sbin/sync.sh

RUN addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -h /home/${APP_USER} -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 chgrp -R ${APP_GROUP} /usr/sbin/sync.sh;

USER ${APP_USER}:${APP_GROUP}

CMD ["/usr/sbin/sync.sh"]
