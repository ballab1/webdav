ARG FROM_BASE=openjdk:20180217
FROM $FROM_BASE


ARG WEBDAV_USER="${CFG_MYSQL_USER}"
ARG WEBDAV_USER_PWD="${CFG_MYSQL_PASSWORD}"
ARG WEBDAV_GROUP='bobb'
ARG WEBDAV_READWRITE='disable'
ARG WEBDAV_WHITELIST='127.0.0.1'

# version of this docker image
ARG CONTAINER_VERSION=1.0.2
LABEL version=$CONTAINER_VERSION 


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh 'WEBDAV'
RUN rm -rf /tmp/* 


# We expose webdav on port 80
#EXPOSE 80
#USER $WEBDAV_USER
#VOLUME [ "/webdav" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["webdav"]
