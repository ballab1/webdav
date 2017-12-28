#!/bin/bash

# ENV params:   USERNAME, PASSWD, GROUP, READWRITE, WHITELIST


set -o errexit

export WEBDAV_HOME="${WEBDAV_HOME:-/webdav}"
declare webdav_user="${USERNAME:-webdav}"
declare webdav_pwd="${PASSWD}"
declare webdav_group="${GROUP:-webdav}"


function isReadOnly()
{
    # Only allow read access by default
    READWRITE=${READWRITE:=false}

    local isRO='"enable"'
    [[ "$READWRITE" == "true" ]] && isRO='"disable"'
    echo "s|is-readonly = \"\\w*\"|is-readonly = ${isRO}|"
}

function setHtPasswd()
{
    local -r webdav_user=$1
    local -r webdav_pwd=$2
    
    [[ -z "${webdav_user}" || -z "${webdav_pwd}" ]] && return
    sudo rm /etc/lighttpd/htpasswd
    echo "${webdav_pwd}" | sudo htpasswd -c /etc/lighttpd/htpasswd "${webdav_user}"
    sudo chmod 444 /etc/lighttpd/htpasswd
}

function setPermissionsOnVolumes()
{
    local webdav_user=$1
    local webdav_group=$2

    sudo chmod 777 -R /var/log
    sudo chown "${webdav_user}":"${webdav_group}" /var/log
    sudo chown "${webdav_user}":"${webdav_group}" /etc/lighttpd/htpasswd
    sudo chown "${webdav_user}:${webdav_group}" -R "${WEBDAV_HOME}"
}

function updateWhiteList()
{
    [[ -n "$WHITELIST" ]] && sed -i "s/WHITELIST/${WHITELIST}/" /etc/lighttpd/webdav.conf
    sudo sed -i "$( isReadOnly )" /etc/lighttpd/webdav.conf
}


#[[ -e /config ]] && ln -s /config /etc/lighttpd
webdav_user='webdav'
webdav_group='webdav'

if [ "$1" = 'webdav' ]; then
    setHtPasswd "$webdav_user" "$webdav_pwd"
    updateWhiteList    
    setPermissionsOnVolumes "$webdav_user" "$webdav_group"

    lighttpd -f /etc/lighttpd/lighttpd.conf -D
else
    exec $@
fi
