FROM php:7.3-fpm-alpine

ENV S6RELEASE v1.22.1.0
ENV S6URL https://github.com/just-containers/s6-overlay/releases/download/
ENV S6_READ_ONLY_ROOT 1

RUN apk add --update \
    # Install nginx
	&& apk add nginx apache2-utils \
	# Install s6 overlay for service management
	&& apk add gnupg \
    && wget -qO - https://keybase.io/justcontainers/key.asc | gpg2 --import - \
    && cd /tmp \
    && S6ARCH=$(uname -m) \
    && case ${S6ARCH} in \
           x86_64) S6ARCH=amd64;; \
           armv7l) S6ARCH=armhf;; \
       esac \
    && wget -q ${S6URL}${S6RELEASE}/s6-overlay-${S6ARCH}.tar.gz.sig \
    && wget -q ${S6URL}${S6RELEASE}/s6-overlay-${S6ARCH}.tar.gz \
    && gpg2 --verify s6-overlay-${S6ARCH}.tar.gz.sig \
    && tar -xzf s6-overlay-${S6ARCH}.tar.gz -C / \
	# Support running s6 under a non-root user
    && mkdir -p /etc/services.d/nginx/supervise /etc/services.d/php-fpm/supervise /run/nginx \
    && mkfifo \
        /etc/services.d/nginx/supervise/control \
        /etc/services.d/php-fpm/supervise/control \
        /etc/s6/services/s6-fdholderd/supervise/control \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx \
    && adduser nobody www-data \
    && chown -R nobody.www-data /etc/services.d /etc/s6 /run /var/www \
	# Clean up	
    && rm -rf "${GNUPGHOME}" /tmp/* \
    && apk del gnupg libcap \
	&& rm -rf /var/cache/apk/*

# s6supervisor processes
COPY ./etc/services.d/nginx /etc/services.d/nginx
COPY ./etc/services.d/php-fpm /etc/services.d/php-fpm

# Custom services settings
COPY ./etc/nginx/conf.d/default.conf /etc/nginx/conf.d/

COPY ./composer.sh /tmp/composer.sh
RUN chmod +x /tmp/composer.sh && /tmp/./composer.sh
ENV COMPOSER_ALLOW_SUPERUSER 1

# Install monolog -viewer from zip (avoiding installing git for composer create-project)
RUN cd /var/www \
    && wget -O monolog-viewer-master.zip https://github.com/krisstwo/monolog-viewer/archive/master.zip \
    && unzip monolog-viewer-master.zip \
    && mv monolog-viewer-master monolog-viewer \
    && rm monolog-viewer-master.zip \
    && cd monolog-viewer \
    && composer install

EXPOSE 80

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD exec /init

WORKDIR /var/www/monolog-viewer