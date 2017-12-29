#!/bin/bash

function isReadOnly()
{
    local -r isReadWrite=$1

    local isRO='"enable"'
    case "$isReadWrite" in
        true)      isRO='"disable"';break;;
        "true")    isRO='"disable"';break;;
        'true')    isRO='"disable"';break;;
        yes)       isRO='"disable"';break;;
        "yes")     isRO='"disable"';break;;
        'yes')     isRO='"disable"';break;;
        enable)    isRO='"disable"';break;;
        "enable")  isRO='"disable"';break;;
        'enable')  isRO='"disable"';break;;
        enabled)   isRO='"disable"';break;;
        "enabled") isRO='"disable"';break;;
        'enabled') isRO='"disable"';break;;
    esac

    echo "s_is-readonly = \"\\w*\"_is-readonly = ${isRO}_g"
}

function setHtPasswd()
{
    local -r conf_dir=$1
    local -r user=$2
    local -r pwd=$3

    [[ -z "$user" || -z "$pwd" ]] && return

    local -r pwd_file="${conf_dir}/htpasswd"
    rm "$pwd_file"
    echo "$pwd" | htpasswd -c "$pwd_file" "$user"
    chmod 444 "$pwd_file"
    chown "$user" "${conf_dir}/"*
}

function setFilePermissions()
{
    local -r conf_dir=$1
    local -r user=$2
    local -r group=$3
    local -r home_dir=$4

    touch /run/lighttpd.pid
    chown "$user":"$group" /run/lighttpd.pid
    
    chmod 777 -R /var/log
    chown "$user":"$group" /var/log
    chown "$user":"$group" "${conf_dir}/"*
    chown "$user":"$group" -R "$home_dir"
}

function setUserAngGroupAccess()
{
    local -r conf_dir=$1
    local -r user=$2
    local -r group=$3
    echo "${conf_dir}/lighttpd.conf"
    
    local f1="^.*server.username\s+=.*\$"
    local t1=" server.username = ${user}"
    sed -i "s_${f1}_${t1}_" "${conf_dir}/lighttpd.conf"

    local f2="^.*server.groupname\s+=.*\$"
    local t2=" server.groupname = ${group}"
    sed -i "s_${f2}_${t2}_" "${conf_dir}/lighttpd.conf"
}

function setWhiteList()
{
    local -r conf_dir=$1
    local -r read_write=$2
    local -r whitelist=$3
    
    [[ -n "$whitelist" ]] && sed -i "s/WHITELIST/${whitelist}/" "${conf_dir}/webdav.conf"
    sed -i "$( isReadOnly $read_write )" "${conf_dir}/webdav.conf"
}

function setConfigParams()
{
    local -r conf_dir=$1
    local -r home_dir=$2
    local -r user=$3
    local -r pwd=$4
    local -r group=$5
    local -r whitelist=$6
    local -r readwrite=$7
    
    setFilePermissions "$conf_dir" "$user" "$group" "$home_dir"
    setHtPasswd "$conf_dir" "$user" "$pwd"
    setUserAngGroupAccess "$conf_dir" "$user" "$group"
    setWhiteList "$conf_dir" "$readwrite" "$whitelist"
}

function updateConfigParams()
{
    local -r conf_dir=$1
    local home_dir=$2
    local user=$3
    local -r pwd=$4
    local group=$5
    local whitelist=$6
    local readwrite=$7

    local -r cfg_user=$( cat "${conf_dir}/lighttpd.conf" | grep 'server.username' | sed 's_^.+=\s+"?([!"]+)"?$_\1_' )
    local -r cfg_group=$( cat "${conf_dir}/lighttpd.conf" | grep 'server.groupname' | sed 's_^.+=\s+"?([!"]+)"?$_\1_' )
    local -r cfg_home_dir=$( cat "${conf_dir}/lighttpd.conf" | grep 'server.document-root' | sed 's_^.+=\s+"?([!"]+)"?$_\1_' )
    local -r cfg_whitelist=$( cat "${conf_dir}/webdav.conf" | grep 'webdav.is-readonly' | sed 's_^.+=\s+"?([!"]+)"?$_\1_' )
    local -r cfg_readonly=$( cat "${conf_dir}/webdav.conf" | grep 'webdav.is-readonly' | sed 's_^.+=\s+"?([!"]+)"?$_\1_' )
    
    setFilePermissions "$conf_dir" "$user" "$group" "$home_dir"

    [[ -z $user ]]  && user=$cfg_user
    [[ -z $group ]] && group=$cfg_group
    [[ -z $whitelist ]] && whitelist=$cfg_whitelist
    [[ -z $readwrite ]] && readwrite=$cfg_readonly

    [[ $cfg_user != $user ]] && setHtPasswd "$conf_dir" "$user" "$pwd"
    [[ $cfg_user != $user || $cfg_group != $group ]] && setUserAngGroupAccess "$conf_dir" "$user" "$group"
    [[ $cfg_readonly != $readwrite || $cfg_whitelist != $whitelist ]] && setWhiteList "$conf_dir" "$readwrite" "$whitelist"
}
