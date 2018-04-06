ARG FROM_BASE=openjdk:20180314
FROM $FROM_BASE

# name and version of this docker image
ARG CONTAINER_NAME=webdav
ARG CONTAINER_VERSION=1.0.0

LABEL org_name=$CONTAINER_NAME \
      version=$CONTAINER_VERSION 

# set to non zero for the framework to show verbose action scripts
#    (0:default, 1:trace & do not cleanup; 2:continue after errors)
ARG DEBUG_TRACE=0
# Specify CBF version to use with our configuration and customizations
ARG CBF_VERSION=${CBF_VERSION:-v2.0}
# inclide our project files
COPY build /tmp/


ARG webdav_uid=1953
ARG webdav_gid=1953
ARG WEBDAV_READWRITE='disable'
ARG WEBDAV_WHITELIST='127.0.0.1'


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
