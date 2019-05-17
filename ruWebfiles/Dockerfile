FROM alpine

ARG APP_USER
ARG APP_GROUP

RUN apk update && \
 apk upgrade && \
 apk add --no-cache git;

COPY getfiles.sh /usr/sbin/
RUN chmod +x /usr/sbin/getfiles.sh

RUN addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -H -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 chgrp -R ${APP_GROUP} /usr/sbin/getfiles.sh;

CMD ["/usr/sbin/getfiles.sh"]
