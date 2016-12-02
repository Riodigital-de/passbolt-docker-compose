FROM openjdk:8u111-jre-alpine

ARG FOO
ARG BAR

COPY ./static.config /opt/someProgram/wontTouchagain.conf
COPY ./some.file /tmp/justForBuild.file

COPY ./run.sh /run.sh
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN echo "FOO = " $FOO
RUN if ( $BAR ); then echo "BAR is true"; fi

RUN chmod +x /docker-entrypoint.sh
RUN chmod +x /run.sh

RUN apk update
RUN apk add wget
RUN apk add curl ca-certificates
RUN apk add supervisor bzip2

RUN update-ca-certificates

EXPOSE 9000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/run.sh]