FROM alpine:3.6

ARG TZ="America/New_York"
ARG USERNAME="${CFG_MYSQL_USER}"
ARG PASSWD="${CFG_MYSQL_PASSWORD}"
ARG GROUP='bobb'
#ARG READWRITE=''
#ARG WHITELIST=''

ENV VERSION=1.0.0 \
    USERNAME="${CFG_MYSQL_USER}" \
    PASSWD="${CFG_MYSQL_PASSWORD}" \
    GROUP='bobb'
    
    
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

# We expose phpMyAdmin on port 80
#EXPOSE 80

#VOLUME [ "/config", "/webdav" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["webdav"]
