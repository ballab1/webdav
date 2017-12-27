#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r CONTAINER='WEBDAV'

export TZ=${TZ:-'America/New_York'}
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  


declare -r CORE_PKGS="lighttpd lighttpd-mod_webdav lighttpd-mod_auth tzdata"


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
}

#############################################################################
function installAlpinePackages() {
    apk update
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
installAlpinePackages
installTimezone
install_WEBDAV
setPermissions
#cleanup
exit 0 