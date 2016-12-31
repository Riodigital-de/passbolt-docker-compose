FROM nginx:latest

RUN set -x \
    && echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update --quiet \
    && apt-get install --quiet --yes --no-install-recommends certbot -t jessie-backports supervisor cron

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
# lets reroute the scripts output to a logfile
RUN sed --in-place 's/renew/renew \>\> \/var\/log\/cert-renew.log/g' /etc/cron.d/certbot
# create and persist the logfile for certbot renewal cronjob
RUN touch /var/log/cert-renew.log
VOLUME ["/var/log/"]

COPY ./supervisor.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./nginx.conf /etc/nginx/nginx.conf
#COPY ./desk.template.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]