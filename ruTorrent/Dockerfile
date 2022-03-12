FROM ubuntu

ARG APP_USER=rutorrent
ARG APP_GROUP=rutorreent
ARG RUUSER=rutorrent
ARG PORT=5001
ARG DHTPORT=6881
ARG FILEBOT_VERSION=4.9.4

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries && \
    apt-get update && \
    apt-get install -y software-properties-common locales && \
    apt-add-repository universe && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get -y full-upgrade && \
    apt-get -y install apache2-utils \
        apt-transport-https \
        cmake \
        curl \
        debian-archive-keyring \
        debian-keyring \
        ffmpeg \
        git \
        lftp \
        mediainfo \
        net-tools \
        p7zip-full \
        php5.6-cli \
        php5.6-mcrypt \
        php5.6-zip \
        python3-pip \
        rtorrent \
        screen \
        screen \
        sox \
        unrar \
        unzip \
        wget && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt update && \
    apt install -y caddy && \
    pip3 install cfscrape && \
    wget -S "https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}_universal.deb" && \
    apt -y install ./FileBot_${FILEBOT_VERSION}_universal.deb && \
    mkdir -p /torrents /etc/filebot /app /app-data;

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
 dpkg-reconfigure --frontend=noninteractive locales && \
 update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8 

COPY torrent.sh /usr/sbin/
RUN chmod +x /usr/sbin/torrent.sh

RUN groupadd -g 1000 ${APP_GROUP} && \
 useradd -u 1000 -c "Torrent User" -d /torrents/${RUUSER} -g ${APP_GROUP} -m ${RUUSER} && \
 mkdir -p /torrents/${RUUSER}/.filebot/cache && \
 chown -R ${RUUSER}:${APP_GROUP} /torrents /etc/filebot /torrents/${RUUSER}/.filebot /app /app-data && \
 ls -al /torrents/${RUUSER}

USER ${RUUSER}:${APP_GROUP}

EXPOSE $PORT $DHTPORT
CMD ["/usr/sbin/torrent.sh"]
