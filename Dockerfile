FROM php:7-fpm-alpine

ENV PS1 '\u@\h:\w\$ '

RUN apk --no-cache add --upgrade icu-libs libpq \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS icu-dev curl-dev postgresql-dev \
    && docker-php-ext-install \
        pdo pdo_mysql pdo_pgsql \
        intl \
        curl \
    && pecl install \
        xdebug \
        redis \
        apcu \
        pcov \
    && apk del .phpize-deps \
    && docker-php-ext-enable apcu intl opcache pdo curl redis pdo_mysql pcov \
    && rm -rf /var/cache/apk/*

COPY php.ini /usr/local/etc/php/conf.d/
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

WORKDIR /app
EXPOSE 9000
ENTRYPOINT ["entrypoint"]
CMD ["php-fpm"]
