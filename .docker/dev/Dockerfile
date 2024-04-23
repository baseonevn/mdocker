ARG PHP_MOD=fpm
ARG PHP_VERSION=8.2
ARG COMPOSER_VERSION=2.4.4

# Composer build
FROM composer:${COMPOSER_VERSION} as composer
WORKDIR "/public_html"

COPY var/composer_home/cache ${COMPOSER_HOME}/cache

# PHP
FROM php:${PHP_VERSION}-${PHP_MOD}
WORKDIR "/public_html"

ARG UID=1000
ARG GID=1000

RUN usermod -u ${UID} www-data
RUN groupmod -g ${GID} www-data

RUN apt-get update && \
  apt-get install -y --no-install-recommends --no-install-suggests \
  libxml2-dev \
  libxslt1-dev \
  libzip-dev \
  libbz2-dev \
  libwebp-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libonig-dev \
  libsodium-dev \
  libmagickwand-dev \
  libssh2-1-dev \
  cron \
  git && rm -rf /var/lib/apt/lists/*

RUN pecl channel-update pecl.php.net && pecl install \
    imagick \
    redis \
    xdebug \
  && pecl clear-cache \
  && rm -rf /tmp/pear

RUN docker-php-ext-configure \
    gd --with-freetype --with-jpeg --with-webp

RUN docker-php-ext-install \
    bcmath \
    bz2 \
    calendar \
    exif \
    gd \
    gettext \
    intl \
    mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    sodium \
    sysvmsg \
    sysvsem \
    sysvshm \
    xsl \
    zip \
  && docker-php-ext-enable \
    imagick \
    redis 

COPY settings/php/php-ext.ini /usr/local/etc/php/conf.d/php-ext.ini
COPY settings/cron /etc/cron.d/cron
RUN chmod 0644 /etc/cron.d/cron
RUN crontab /etc/cron.d/cron

RUN touch /var/log/cron.log

USER www-data
COPY --chown=www-data:www-data --from=composer /usr/bin/composer /usr/bin/composer
COPY --chown=www-data:www-data --from=composer /tmp/cache /tmp/cache
RUN chmod +x /usr/bin/composer

COPY --chown=www-data:www-data --from=composer /public_html .
COPY --chown=www-data:www-data src .
RUN echo ${UID}
ENV MAGE_MODE=developer
RUN chmod +x ./bin/magento

EXPOSE 9000
CMD ["/bin/bash", "-c", "php-fpm"]
