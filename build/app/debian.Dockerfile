FROM debian

ARG LOG_ERROR
ARG LOG_ACCESS
ARG MEMORY_LIMIT
ARG POST_MAXSIZE
ARG UPLOAD_MAX_FILESIZE
ARG DATE_TIMEZONE


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # persistent &runtime deps. \
    ca-certificates curl wget libpcre3 librecode0 libsqlite3-0 libxml2 \
    # versioning & package manager tools \
    git npm \
    # php \
    php5-json php5-cli php5-fpm php5-common \
    php5-curl php5-gd php5-mcrypt \
    php5-mysql php5-xsl php5-intl \

    # gpg
    libgpgme11-dev\
    # cache
    php5-memcached memcached\
    # pear
    php-pear \
    # supervisor
    supervisor

# Configure the user www-data environment
RUN mkdir /home/www-data/ \
    && chown www-data:www-data /home/www-data/ \
    && usermod -d /home/www-data www-data

RUN mkdir /var/www

# Configure node and install grunt
# On debian they choose to rename node in nodejs, some tools try to access nodejs by using the commande noe.
RUN ln -s /usr/bin/nodejs /usr/bin/node \
    # install grunt
    && npm install -g grunt-cli

RUN apt-get install -y --no-install-recommends \
     # phpize dependencies \
    autoconf file g++ gcc libc-dev make pkg-config re2c php5-dev

RUN pecl install gnupg \
    && echo "extension=gnupg.so;" > /etc/php5/mods-available/gnupg.ini \
    && ln -s /etc/php5/mods-available/gnupg.ini /etc/php5/fpm/conf.d/20-gnupg.ini \
    && ln -s /etc/php5/mods-available/gnupg.ini /etc/php5/cli/conf.d/20-gnupg.ini \
    # configure the user www-data env to work with gnupg \
    && mkdir /home/www-data/.gnupg \
    && chown www-data:www-data /home/www-data/.gnupg \
    && chmod 0777 /home/www-data/.gnupg

RUN apt-get remove -y \
    autoconf file g++ gcc libc-dev make pkg-config re2c php5-dev

## php config
# config php5-fpm to use port 9000 instead of a unix socket
RUN sed -i "/listen =/c\listen = \[\:\:\]\:9000" /etc/php5/fpm/pool.d/www.conf

# reroute php access and error log for display in docker log
# we dont configure this for cli, since whoever is logged into a container to use the cli will see the output anyway
RUN if ( $LOG_ERROR ); then  sed -i "/error_log =/c\error_log = \/proc\/self\/fd\/2" /etc/php5/fpm/php-fpm.conf; fi
RUN if ( $LOG_ACCESS ); then  sed -i "/;access.log =/c\access.log = \/proc\/self\/fd\/2" /etc/php5/fpm/pool.d/www.conf; fi

# file size configs
RUN sed -i "/memory_limit =/c\memory_limit = $MEMORY_LIMIT" /etc/php5/fpm/php.ini
RUN sed -i "/memory_limit =/c\memory_limit = $MEMORY_LIMIT" /etc/php5/cli/php.ini
RUN sed -i "/post_max_size =/c\post_max_size = $POST_MAXSIZE" /etc/php5/fpm/php.ini
RUN sed -i "/post_max_size =/c\post_max_size = $POST_MAXSIZE" /etc/php5/cli/php.ini
RUN sed -i "/upload_max_filesize =/c\upload_max_filesize = $UPLOAD_MAX_FILESIZE" /etc/php5/fpm/php.ini
RUN sed -i "/upload_max_filesize =/c\upload_max_filesize = $UPLOAD_MAX_FILESIZE" /etc/php5/cli/php.ini

# date timezone
RUN sed -i "/;date.timezone =/c\date.timezone = $DATE_TIMEZONE" /etc/php5/fpm/php.ini
RUN sed -i "/;date.timezone =/c\date.timezone = $DATE_TIMEZONE" /etc/php5/cli/php.ini

RUN mkdir /run/php

# install compose
COPY ./install-composer-debian.sh /tmp/install-composer.sh
RUN chmod +x /tmp/install-composer.sh && /tmp/install-composer.sh
RUN mv /composer.phar /usr/local/bin/composer

RUN apt-get install -y --no-install-recommends cron

# cron for mail
COPY ./mailer-cron /etc/cron.d/mailer-cron
RUN chmod 0644 /etc/cron.d/mailer-cron
RUN touch /var/log/passbolt.log

# supervisor
COPY ./supervisor.conf /etc/supervisor/conf.d/supervisor.conf
RUN chmod 0644 /etc/supervisor/conf.d/supervisor.conf

# gpg keys
COPY ./gnupg/gpg_server_key_public.key /home/www-data/gpg_server_key_public.key
COPY ./gnupg/gpg_server_key_private.key /home/www-data/gpg_server_key_private.key

COPY ./gnupg /root/.gnupg
COPY ./gnupg /home/www-data/.gnupg
RUN chown -R www-data /home/www-data

RUN chown -R www-data /home/www-data

EXPOSE 9000

# cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get autoremove -y
RUN rm -rf /tmp/*

COPY ./run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]