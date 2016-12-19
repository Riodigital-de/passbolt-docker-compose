FROM debian:jessie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    haveged gettext-base
    
COPY ./bin/gen-keys.sh /gen-keys.sh
RUN chmod +x /gen-keys.sh

COPY ./config/gpg-key.conf.template /gpg-key.conf.template

RUN mkdir /keys

CMD ["/gen-keys.sh"]