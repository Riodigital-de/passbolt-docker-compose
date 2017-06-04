FROM nginx:stable

RUN set -x \
    && echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends certbot -t jessie-backports supervisor cron \
    # temporary fix for
    # https://community.letsencrypt.org/t/the-ndg-httpsclient-distribution-was-not-found-error/33084
    # see
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=861513
    && apt-get install python-ndg-httpsclient -t jessie-backports

# dry-run.sh is to test current config and obtain fake pem files
COPY ./dry-run.sh /dry-run.sh
RUN chmod +x /dry-run.sh

# this actually tries to obtain the cert files, be sure to fires this only after you used dry run to test!
# letsencrypt still has very hard limits on how often they issue certs for each domain
COPY ./get-cert.sh /get-cert.sh
RUN chmod +x /get-cert.sh

# persist letsencrypt files
VOLUME ["/etc/letsencrypt", "/var/lib/letsencrypt"]

# certbot debian jessie package installs a cronjob at /etc/cron.d/certbot to automatically renew certs twice a day
# we need to modify this since certbot still doesn't play very well with nginx
RUN sed --in-place '/0 \*\/12 \* \* \* root test -x/c\0 \*\/12 \* \* \* nginx -s stop && certbot -q renew && nginx -g "daemon off;" >> \/var\/log\/cert-renew.log' /etc/cron.d/certbot
# create and persist the logfile for certbot renewal cronjob
RUN touch /var/log/cert-renew.log
VOLUME ["/var/log/"]

COPY ./supervisor.conf /etc/supervisor/conf.d/supervisord.conf

COPY ./run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 80 443

CMD ["/run.sh"]