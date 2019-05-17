FROM ubuntu

ARG APP_USER
ARG APP_GROUP
ARG RUUSER
ARG PORT
ARG DHTPORT

ENV DEBIAN_FRONTEND noninteractive

RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries && \
 apt -y update && \
 apt-get install -y software-properties-common && \
 add-apt-repository ppa:ondrej/php && \
 apt -y update && \
 apt -y upgrade && \
 apt-get -y install python-pip sox unzip php5.6-cli php5.6-mcrypt php5.6-zip git wget curl mediainfo ffmpeg cmake screen lftp unrar apache2-utils rtorrent p7zip-full screen net-tools && \
 pip install cfscrape && \
 wget -S "https://get.filebot.net/filebot/FileBot_4.8.5/FileBot_4.8.5_universal.deb" && \
 apt -y install ./FileBot_4.8.5_universal.deb && \
 mkdir -p /torrents /etc/filebot /app /app-data;

COPY torrent.sh /usr/sbin/
RUN chmod +x /usr/sbin/torrent.sh

RUN groupadd -g 1000 ${APP_GROUP} && \
 useradd -u 1000 -c "Torrent User" -d /torrents/${RUUSER} -g ${APP_GROUP} -m ${RUUSER} && \
 chown -R ${RUUSER}:${APP_GROUP} /torrents /etc/filebot /app /app-data;

USER ${RUUSER}:${APP_GROUP}

EXPOSE $PORT $DHTPORT
CMD ["/usr/sbin/torrent.sh"]
