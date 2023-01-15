FROM ubuntu

ARG FILEBOT_VERSION=4.9.6

RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries && \
    export DEBIAN_FRONTEND=noninteractive && \
    export LANG=en_US.UTF-8 && \
    apt-get update && \
    apt-get install -y ca-certificates software-properties-common locales && \
    sed -i 's/htt[p|ps]:\/\/archive.ubuntu.com\/ubuntu\//mirror:\/\/mirrors.ubuntu.com\/mirrors.txt/g' /etc/apt/sources.list && \
    apt-add-repository -y universe && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get update && \
    apt-get -y full-upgrade && \
    apt-get -y install apache2-utils \
        apt-transport-https \
        cmake \
        curl \
        debian-archive-keyring \
        debian-keyring \
        ffmpeg \
        file \
        git \
        jq \
        lftp \
        mediainfo \
        net-tools \
        p7zip-full \
        php8.1-cli \
        php8.1-mcrypt \
        php8.1-zip \
        python3-pip \
        rtorrent \
        screen \
        screen \
        sox \
        unrar \
        unzip \
        wget \
        zsh && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update && \
    apt-get install -y caddy && \
    wget -S "https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}_universal.deb" && \
    apt-get -y install ./FileBot_${FILEBOT_VERSION}_universal.deb && \
    apt-get -y autoremove && \
    mkdir -p /torrents /etc/filebot /app /app-data && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    pip3 install cfscrape yt-dlp pycryptodome

ARG APP_USER=rutorrent
ARG APP_GROUP=rutorrent
ARG RUUSER=rutorrent
ARG PORT=5001
ARG DHTPORT=6881

RUN groupadd -g 1000 ${APP_GROUP} && \
 useradd -u 1000 -c "Torrent User" -d /torrents/${RUUSER} -g ${APP_GROUP} -m -s /usr/sbin/nologin ${RUUSER} && \
 su - ${RUUSER} -s "/usr/bin/zsh" -c "pip3 install cfscrape yt-dlp pycryptodome" && \
 mkdir -p /torrents/${RUUSER}/.filebot/cache

COPY .zshrc.source /torrents/${RUUSER}/.zshrc
COPY rootfs/ /

RUN chown -R ${RUUSER}:${APP_GROUP} /torrents /etc/filebot /torrents/${RUUSER}/.filebot /app /app-data

USER ${RUUSER}:${APP_GROUP}
ENV LANG=en_US.UTF-8

EXPOSE $PORT $DHTPORT
CMD ["torrent"]
