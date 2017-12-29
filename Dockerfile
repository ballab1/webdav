FROM alpine:3.6

ARG WEBDAV_USER="${CFG_MYSQL_USER}"
ARG WEBDAV_USER_PWD="${CFG_MYSQL_PASSWORD}"
ARG WEBDAV_GROUP='bobb'
ARG WEBDAV_READWRITE='disable'
ARG WEBDAV_WHITELIST='127.0.0.1'

ENV VERSION=1.0.0 \
    TZ="America/New_York"
    
LABEL version=$VERSION

# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && apk update \
    && apk add --no-cache bash \
    && chmod u+rwx /tmp/build_container.sh \
    && /tmp/build_container.sh \
    && rm -rf /tmp/*

# We expose webdav on port 80
#EXPOSE 80
#USER $WEBDAV_USER
#VOLUME [ "/webdav" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["webdav"]
