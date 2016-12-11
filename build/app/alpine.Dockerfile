FROM alpine:3.4

ARG LOG_ERROR
ARG LOG_ACCESS
ARG MEMORY_LIMIT
ARG POST_MAXSIZE
ARG UPLOAD_MAX_FILESIZE
ARG DATE_TIMEZONE

RUN apk update
RUN apk add php5 php5-common php5-fpm php5-gd php5-pdo php5-pdo_mysql php5-mysql php5-mysqli php5-intl php5-json php5-xsl php5-ctype
# filter hash session in common

RUN apk add php5-pear

# gpg
RUN apk add gpgme-dev
RUN pecl install gnupg


RUN apk update
RUN apk add ca-certificates curl wget libpcrecpp sqlite-lib libxml2 recode-dev
RUN apk add git npm
RUN php5 php5-common php5-json php5-gd php5-mcrypt php5-ctype php5-curl php5-mysql php5-xsl php5-intl php5-iconv

RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php

RUN apt-get update && \
    apt-get install -y --no-install-recommends\
    # persistent &runtime deps. \
    ca-certificates curl wget libpcre3 librecode0 libsqlite3-0 libxml2 \
    # versioning & package manager tools \
    git npm \
    # php
    php5.6 php5.6-common php5.6-json php5.6-fpm php5.6-cli php5.6-curl php5.6-gd php5.6-mcrypt php5.6-mysql php5.6-xsl php5.6-intl \
    # gpg
    #php-gnupg libgpgme11-dev\
    libgpgme11-dev\
    # cache
    php-memcached memcached\
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

RUN pecl install gnupg \
    && echo "extension=gnupg.so;" > /etc/php5/mods-available/gnupg.ini \
    && ln -s /etc/php5/mods-available/gnupg.ini /etc/php5/apache2/conf.d/20-gnupg.ini \
    && ln -s /etc/php5/mods-available/gnupg.ini /etc/php5/cli/conf.d/20-gnupg.ini \
    # configure the user www-data env to work with gnupg \
    && mkdir /home/www-data/.gnupg \
    && chown www-data:www-data /home/www-data/.gnupg \
    && chmod 0777 /home/www-data/.gnupg

## php config
# config php5.6-fpm to use port 9000 instead of a unix socket
RUN sed -i "/listen =/c\listen = \[\:\:\]\:9000" /etc/php/5.6/fpm/pool.d/www.conf

# reroute php access and error log for display in docker log
# we dont configure this for cli, since whoever is logged into a container to use the cli will see the output anyway
RUN if ( $LOG_ERROR ); then  sed -i "/error_log =/c\error_log = \/proc\/self\/fd\/2" /etc/php/5.6/fpm/php-fpm.conf; fi
RUN if ( $LOG_ACCESS ); then  sed -i "/;access.log =/c\access.log = \/proc\/self\/fd\/2" /etc/php/5.6/fpm/pool.d/www.conf; fi

# file size configs
RUN sed -i "/memory_limit =/c\memory_limit = $MEMORY_LIMIT" /etc/php/5.6/fpm/php.ini
RUN sed -i "/memory_limit =/c\memory_limit = $MEMORY_LIMIT" /etc/php/5.6/cli/php.ini
RUN sed -i "/post_max_size =/c\post_max_size = $POST_MAXSIZE" /etc/php/5.6/fpm/php.ini
RUN sed -i "/post_max_size =/c\post_max_size = $POST_MAXSIZE" /etc/php/5.6/cli/php.ini
RUN sed -i "/upload_max_filesize =/c\upload_max_filesize = $UPLOAD_MAX_FILESIZE" /etc/php/5.6/fpm/php.ini
RUN sed -i "/upload_max_filesize =/c\upload_max_filesize = $UPLOAD_MAX_FILESIZE" /etc/php/5.6/cli/php.ini

# date timezone
RUN sed -i "/;date.timezone =/c\date.timezone = $DATE_TIMEZONE" /etc/php/5.6/fpm/php.ini
RUN sed -i "/;date.timezone =/c\date.timezone = $DATE_TIMEZONE" /etc/php/5.6/cli/php.ini

RUN mkdir /run/php

# install compose
COPY ./install-composer-debian.sh /tmp/install-composer.sh
RUN chmod +x /tmp/install-composer.sh && /tmp/install-composer.sh
RUN mv /composer.phar /usr/local/bin/composer

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