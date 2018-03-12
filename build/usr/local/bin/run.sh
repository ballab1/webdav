#!/bin/bash

declare conf_dir="${WEBDAV_CONF_DIR:-/etc/lighttpd}" 
echo "starting lighttpd -f '${conf_dir}/lighttpd.conf' -D"
lighttpd -f "${conf_dir}/lighttpd.conf" -D
