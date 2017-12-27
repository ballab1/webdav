#!/bin/sh

set -o errexit

# Force user and group because lighttpd runs as webdav
USERNAME=${USERNAME:-webdav}
GROUP=${GROUP:-webdav}

# Only allow read access by default
READWRITE=${READWRITE:=false}


if [ "$1" = 'webdav' ]; then

    # Add user if it does not exist
    if ! id -u "${USERNAME}" >/dev/null 2>&1; then
      addgroup -g ${USER_GID:=2222} ${GROUP}
      adduser -G ${GROUP} -D -H -u ${USER_UID:=2222} ${USERNAME}
    fi

    chown "${USERNAME}":"${GROUP}" /var/log

    [[ -n "$WHITELIST" ]] && sed -i "s/WHITELIST/${WHITELIST}/" /etc/lighttpd/webdav.conf

    if [ "$READWRITE" == "true" ]; then
      sed -i "s/is-readonly = \"\\w*\"/is-readonly = \"disable\"/" /etc/lighttpd/webdav.conf
    else
      sed -i "s/is-readonly = \"\\w*\"/is-readonly = \"enable\"/" /etc/lighttpd/webdav.conf
    fi

    [[ ! -f /config/htpasswd    ]] &&  cp /etc/lighttpd/htpasswd /config/htpasswd
    [[ ! -f /config/webdav.conf ]] &&  cp /etc/lighttpd/webdav.conf /config/webdav.conf

    lighttpd -f /etc/lighttpd/lighttpd.conf

    # Hang on a bit while the server starts
    sleep 3665

    tail -f /var/log/lighttpd/*.log

else
    exec $@
fi
