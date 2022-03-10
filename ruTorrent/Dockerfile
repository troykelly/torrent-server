FROM ubuntu

ARG APP_USER
ARG APP_GROUP
ARG RUUSER
ARG PORT
ARG DHTPORT
ARG FILEBOT_VERSION=4.9.4

ENV DEBIAN_FRONTEND noninteractive

RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries && \
 apt-get update && \
 apt-get install -y software-properties-common locales && \
 apt-add-repository universe && \
 add-apt-repository ppa:ondrej/php && \
 apt-get update && \
 apt-get -y upgrade && \
 apt-get -y install python3-pip sox unzip php5.6-cli php5.6-mcrypt php5.6-zip git wget curl mediainfo ffmpeg cmake screen lftp unrar apache2-utils rtorrent p7zip-full screen net-tools && \
 pip3 install cfscrape && \
 wget -S "https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}_universal.deb" && \
 apt -y install ./FileBot_${FILEBOT_VERSION}_universal.deb && \
 mkdir -p /torrents /etc/filebot /app /app-data;

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
 dpkg-reconfigure --frontend=noninteractive locales && \
 update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

COPY torrent.sh /usr/sbin/
RUN chmod +x /usr/sbin/torrent.sh

RUN groupadd -g 1000 ${APP_GROUP} && \
 useradd -u 1000 -c "Torrent User" -d /torrents/${RUUSER} -g ${APP_GROUP} -m ${RUUSER} && \
 mkdir -p /torrents/${RUUSER}/.filebot/cache && \
 chown -R ${RUUSER}:${APP_GROUP} /torrents /etc/filebot /torrents/${RUUSER}/.filebot /app /app-data;

USER ${RUUSER}:${APP_GROUP}

EXPOSE $PORT $DHTPORT
CMD ["/usr/sbin/torrent.sh"]
