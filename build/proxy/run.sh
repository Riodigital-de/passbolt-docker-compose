#!/usr/bin/env bash

# copy template gnix conf over actual conf
cp /etc/nginx/nginx.conf.template /etc/nginx/nginx.conf

# replace env DOMAIN every time the container is started
sed -i "s/DOMAIN/${DOMAIN}/g" /etc/nginx/nginx.conf

# run nginx and certbot renewal cron via supervisor
/usr/bin/supervisord