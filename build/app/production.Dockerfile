FROM openjdk:8u111-jre-alpine

ARG FOO
ARG BAR

COPY ./static.config /opt/someProgram/wontTouchagain.conf
COPY ./some.file /tmp/justForBuild.file

COPY ./run.sh /run.sh
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN echo "FOO = " $FOO \
    && \
    if ( $BAR ); then echo "BAR is true"; fi \
    && \
    chmod +x \
    /docker-entrypoint.sh \
    /run.sh

RUN apk update \
    && \
    apk add --virtual build-tools \
    wget \
    curl \
    ca-certificates \
    && \
    apk add supervisor bzip2 \
    && \
    update-ca-certificates \
    && \
    apk del build-tools \
    && \
    rm -rf /tmp

EXPOSE 9000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/run.sh]