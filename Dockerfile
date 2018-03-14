ARG FROM_BASE=openjdk:20180314
FROM $FROM_BASE

# name and version of this docker image
ARG CONTAINER_NAME=webdav
ARG CONTAINER_VERSION=1.0.0

LABEL org_name=$CONTAINER_NAME \
      version=$CONTAINER_VERSION 

# set to non zero for the framework to show verbose action scripts
ARG DEBUG_TRACE=0


ARG WEBDAV_USER="${CFG_MYSQL_USER}"
ARG WEBDAV_USER_PWD="${CFG_MYSQL_PASSWORD}"
ARG WEBDAV_GROUP='bobb'
ARG WEBDAV_READWRITE='disable'
ARG WEBDAV_WHITELIST='127.0.0.1'


# Add configuration and customizations
COPY build /tmp/

# build content
RUN set -o verbose \
    && chmod u+rwx /tmp/build.sh \
    && /tmp/build.sh "$CONTAINER_NAME"
RUN [ $DEBUG_TRACE != 0 ] || rm -rf /tmp/* 


# We expose webdav on port 80
#EXPOSE 80
#USER $WEBDAV_USER
#VOLUME [ "/webdav" ]


ENTRYPOINT [ "docker-entrypoint.sh" ]
#CMD ["$CONTAINER_NAME"]
CMD ["webdav"]
