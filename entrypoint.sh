#!/bin/sh
set -e

echo Environnement des containers ${APP_ENV} ${DOCKER_ENV}

# Installations
if [ ! -f /lock-install ]; then

    if [ "${DOCKER_ENV}" = "prod" ]; then
        # active
        echo "Production"
    fi

    # Installation de composer
    if [ "${DOCKER_ENV}" = "test" -o "${DOCKER_ENV}" = "dev" -o "${APP_ENV}" = "build" ]; then
        echo Installation Composer
	    echo "memory_limit = 2048M ;" > /usr/local/etc/php/php.ini
        COMPOSER_ALLOW_SUPERUSER=1        
        EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
        if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
        then
            >&2 echo 'ERROR: Invalid installer signature'
            rm composer-setup.php
            exit 1
        fi
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        rm composer-setup.php

        echo Installation Outils
        apk add --no-cache vim curl wget bash bash-completion git
        wget http://cs.symfony.org/download/php-cs-fixer-v2.phar -O /usr/local/bin/php-cs-fixer
        chmod +x /usr/local/bin/php-cs-fixer

        echo Configuration Git
        git config --global user.email "${GIT_USER_EMAIL}"
        git config --global user.name "${GIT_USER_NAME}"

        echo Installation commande Symfony
        wget https://get.symfony.com/cli/installer -O - | bash
        mv /root/.symfony/bin/symfony /usr/local/bin/symfony
    fi
    echo Fin des installations
    touch /lock-install

fi

# Installation xdebug
[ -f "/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" ] && mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/docker-php-ext-xdebug.ini
if [ "${DOCKER_ENV}" = "test" ]; then
    echo activate xdebug
    [ -f "/usr/local/etc/php/docker-php-ext-xdebug.ini" ] && mv /usr/local/etc/php/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi;

echo exec "$@"
exec "$@"
