FROM php:5-fpm-alpine

ARG APP_USER
ARG APP_GROUP
ARG PHP_ROOT_DIR

RUN apk update && \
 apk upgrade && \
 mkdir -p /usr/local/etc/

COPY www.conf ${PHP_ROOT_DIR}/php-fpm.d/www.conf
COPY php.ini /usr/local/etc/php

RUN addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -H -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 chgrp -R ${APP_GROUP} ${PHP_ROOT_DIR}/php-fpm.d/www.conf /usr/local/etc/php/php.ini && \
 sed -i 's/9000/127.0.0.1:9000/' /usr/local/etc/php-fpm.d/zz-docker.conf && \
 sed -i 's/9000/127.0.0.1:9000/' /usr/local/etc/php-fpm.d/docker.conf