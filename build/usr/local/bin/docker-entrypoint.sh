#!/bin/bash

# ensure this script is run as root
#if [[ $EUID != 0 ]]; then
#    sudo -E $0
#    exit
#fi

# ENV params:   WEBDAV_USER, WEBDAV_USER_PWD, WEBDAV_GROUP, WEBDAV_READWRITE, WEBDAV_WHITELIST

set -o errexit
#source /usr/local/bin/webdav-helper.sh

declare conf_dir="${WEBDAV_CONF_DIR:-/etc/lighttpd}" 

if [ "$1" = 'webdav' ]; then
#    updateConfigParams "$conf_dir" \
#                       "$WEBDAV_HOME" \
#                       "$WEBDAV_USER" \
#                       "$WEBDAV_USER_PWD" \
#                       "$WEBDAV_GROUP" \
#                       "$WEBDAV_WHITELIST" \
#                       "$WEBDAV_READWRITE"
echo "starting lighttpd -f '${conf_dir}/lighttpd.conf' -D"
    lighttpd -f "${conf_dir}/lighttpd.conf" -D
else
    exec $@
fi
