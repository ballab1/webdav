#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r CONTAINER='WEBDAV'

export TZ=${TZ:-'America/New_York'}
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  


declare -r BUILDTIME_PKGS="shadow"
declare -r CORE_PKGS="bash lighttpd lighttpd-mod_webdav lighttpd-mod_auth sudo thttpd tzdata"

#directories
declare -r WEBDAV_HOME=/webdav

#  groups/users
declare -r webdav_user=${webdav_user:-'webdav'}
declare -r webdav_uid=${webdav_uid:-2222}
declare -r webdav_group=${webdav_group:-'webdav'}
declare -r webdav_gid=${webdav_gid:-2222}


# global exceptions
declare -i dying=0
declare -i pipe_error=0


#----------------------------------------------------------------------------
# Exit on any error
function catch_error() {
    echo "ERROR: an unknown error occurred at $BASH_SOURCE:$BASH_LINENO" >&2
}

#----------------------------------------------------------------------------
# Detect when build is aborted
function catch_int() {
    die "${BASH_SOURCE[0]} has been aborted with SIGINT (Ctrl-C)"
}

#----------------------------------------------------------------------------
function catch_pipe() {
    pipe_error+=1
    [[ $pipe_error -eq 1 ]] || return 0
    [[ $dying -eq 0 ]] || return 0
    die "${BASH_SOURCE[0]} has been aborted with SIGPIPE (broken pipe)"
}

#----------------------------------------------------------------------------
function die() {
    local status=$?
    [[ $status -ne 0 ]] || status=255
    dying+=1

    printf "%s\n" "FATAL ERROR" "$@" >&2
    exit $status
}  

#############################################################################
function cleanup()
{
    printf "\nclean up\n"

    apk del .buildDepedencies 
}

#############################################################################
function createUserAndGroup()
{
    local -r user=$1
    local -r uid=$2
    local -r group=$3
    local -r gid=$4
    local -r homedir=$5
    local -r shell=$6
    local result
    
    local wanted=$( printf '%s:%s' $group $gid )
    local nameMatch=$( getent group "${group}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    local idMatch=$( getent group "${gid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: group/gid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"           

    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "\ncreate group:  %s\n" $group
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && groupdel "$( getent group ${group} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && groupdel "$( getent group ${gid} | awk -F ':' '{ print $1 }' )"
        /usr/sbin/groupadd --gid "${gid}" "${group}"
    fi

    
    wanted=$( printf '%s:%s' $user $uid )
    nameMatch=$( getent passwd "${user}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    idMatch=$( getent passwd "${uid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: user/uid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"    
    
    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "create user: %s\n" $user
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && userdel "$( getent passwd ${user} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && userdel "$( getent passwd ${uid} | awk -F ':' '{ print $1 }' )"

        /usr/sbin/useradd --home-dir "$homedir" --uid "${uid}" --gid "${gid}" --no-create-home --shell "${shell}" "${user}"
    fi
}

#############################################################################
function header()
{
    local -r bars='+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    printf "\n\n\e[1;34m%s\nBuilding container: \e[0m%s\e[1;34m\n%s\e[0m\n" $bars $CONTAINER $bars
}
 
#############################################################################
function install_WEBDAV()
{
    printf "\nAdd configuration and customizations\n"
    cp -r "${TOOLS}/etc"/* /etc
    cp -r "${TOOLS}/usr"/* /usr
    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh
    
    [[ -e /etc/lighttpd/htpasswd ]]  && rm /etc/lighttpd/htpasswd
    echo "${PASSWD}" | htpasswd -c /etc/lighttpd/htpasswd "${USERNAME}"
    chmod 444 /etc/lighttpd/htpasswd
}

#############################################################################
function installAlpinePackages()
{
    apk update
    apk add --no-cache --virtual .buildDepedencies $BUILDTIME_PKGS
    apk add --no-cache $CORE_PKGS
}

#############################################################################
function installTimezone() {
    echo "$TZ" > /etc/TZ
    cp /usr/share/zoneinfo/$TZ /etc/timezone
    cp /usr/share/zoneinfo/$TZ /etc/localtime
}

#############################################################################
function setPermissions()
{
    printf "\nmake sure that ownership & permissions are correct\n"

    chmod u+rwx /usr/local/bin/docker-entrypoint.sh
}

#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

header
declare -r USERNAME="${USERNAME?'Envorinment variable USERNAME must be defined'}"
declare -r PASSWD="${PASSWD?'Envorinment variable PASSWD must be defined'}"
installAlpinePackages
createUserAndGroup "${webdav_user}" "${webdav_uid}" "${webdav_group}" "${webdav_gid}" "${WEBDAV_HOME}" /bin/bash
installTimezone
install_WEBDAV
setPermissions
cleanup
exit 0 