#!/usr/bin/ksh
#================================================================
# Common Functions used by uc4scripts
# import this this file with . ${RUNDIR}/functions.ksh
#================================================================

#================================================================
# VARIABLES
#================================================================
prog="$(basename ${0})"
RUNDIR="$( cd "$(dirname "${0}")" && pwd )"
if ! [ -d /var/kubernetes ] ;then
    mkdir -p /var/kubernetes/logs
fi
LOGDIR="/var/kubernetes/logs"
LOG_FILE_DIR="/var/kubernetes/logs"
# Set FUNCITONS_IMPORTED to do not import functions.ksh again
FUNCTIONS_IMPORTED=1
unset PYTHONHOME
unset PYTHONPATH

#================================================================
# GENERAL
#================================================================
k8s_timestamp() {
    date +"%F %T %Z"
}

usage() {
	script_headsize=$(grep -sn "^# END_OF_HEADER" ${0} | head -1 | cut -f1 -d:)
	printf "Usage: \\n\\n"	
	head -${script_headsize:-99} ${0} | grep -e "^#%" | sed -e "s/^#%//g" -e "s/\${prog}/${prog}/g";
}

runas_root() {
    if [[ ! "root" == "$(id | cut -f 2 -d '(' | cut -f1 -d ')')" ]]; then
        "$(${RUNDIR})" ${RUNDIR}/${prog} "${@}"
        exit
    fi
}

exec_counter() {
    date +"%F %T %Z ${ORACLE_SID:-}" >> ${LOGDIR}/${prog}.stat
}

#================================================================
# MOUNT Share
#================================================================
mount_share() {
    MNT_FOLDER="/workdata"

    if [ ! -d ${MNT_FOLDER} ]; then
        mkdir -p ${MNT_FOLDER}
    fi
    if [ -d ${MNT_FOLDER} ]; then
        if mount|grep -q " ${MNT_FOLDER}";then
          log_info "Something is already mounted on ${MNT_FOLDER}"
          return 1
        elif ! ${RUNDIR}/run_timeout 30 "mount -o vers=4 ${MNT_EXPORT} ${MNT_FOLDER}" > /dev/null 2>&1; then
          log_error "No mount of ${MNT_EXPORT} possible"
          /usr/bin/sendmail.py -t ${AUTOMAIL} -s "${prog}: No mount of ${MNT_EXPORT} possible"
          return 8
        else
          log_info "${MNT_EXPORT} mounted on ${MNT_FOLDER}"
        fi
    fi
}
umount_share() { # $1->mount_export_name
    if [[ "${1}" == "" ]]; then
        MNT_FOLDER="/workdata"
    else
        MNT_FOLDER="${1}"
    fi
    mount | grep -q "${MNT_FOLDER}"
    if [ $? -eq '0' ]; then
        umount ${MNT_FOLDER}
    fi
}
check_software_share() {
    if [[ ! -f /software/AIX/PROD_VERSION.TXT ]]; then
        if ! ${RUNDIR}/run_timeout 30 "mount /workdata" > /dev/null 2>&1; then
            /usr/bin/sendmail.py -t ${AUTOMAIL} -s "${prog}: No /software share available!"
            return 1
        else
            log_info "Mounted /workdata"
        fi
    fi

    # Everything fine
    return 0
}
#================================================================
# UTILITIES
#================================================================
is_reachable() { # $1->host
    if [[ -f /usr/bin/ncat ]]; then
#         /usr/bin/netcat -z -w 1 "${1}" 22 > /dev/null 2>&1
         /usr/bin/ncat -z -w 1 "${1}" 22 > /dev/null 2>&1
    else
        ${RUNDIR}/check_port.py "${1}" 22  > /dev/null 2>&1
    fi
    return ${?}
}

get_ip() { # $1->host
    # dig ${1} +search | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'
    nslookup ${1} | awk '/^Address: / { print $2 }'
}

create_dir() { # $1->path $2->user [$3->group] [$4->mode]
    if [[ -f "${1}" ]]; then
        # Delete if path is file
        rm -f "${1}"
    fi
    if [[ ! -d "${1}" ]]; then
        # Create folder
        mkdir "${1}"
    fi
    if [[ -n "${2}" ]]; then
        # set owner
        chown "${2}" "${1}"
    fi
    if [[ -n "${3}" ]]; then
        # set group
        chgrp "${3}" "${1}"
    fi
    if [[ -n "${4}" ]]; then
        # set mode
        chmod "${4}" "${1}"
    fi
}

#option force delete does not bypass protectedlist
remove_recursive_dir() { # $1->path [$2 -force]
    if [[ ${2} != "force" ]]; then
        forcedelete=n
    else
        forcedelete=y
    fi
    #exists?
    if [[ ! -d "${1}" ]]; then
        # doesn't exist
        log_warning "${1} does not exist"
        return 4
    fi
    #is not in protected list
    if grep -Fxq "${1}" ${RUNDIR}/protected_dir_list ; then
        # is in list
        log_warning "${1} is in protected list - skipping"
        return 4
    fi
    #is empty?
    size="$(du -sm ${1} | awk '{print $1}')"
    if [[ "${size}" != "0.00" && "$forcedelete" != "y" ]]; then
        log_info "${1} size not 0 but ${size} and force not selected - skipping"
        return 4
    fi
    log_info "removing ${1}"
    rm -rf "${1}"
}

###############################################################################
# Ask question that should be answered with y/n. Return value is dependend on
# answer:
#   y -> 0
#   n -> 1
#   other -> 8
#
# Globals:
#   
# Arguments:
#   question
#   auto
#   logfile
#
###############################################################################
ask_yn() {
    answer=n
    if [[ -z ${2} || "${2}" != "y" ]]; then
        log_info "${1} (y/n)?"
        read -r answer 
        if [[ -n ${3} ]]; then
            print "\n${1} (y/n) : $answer" >>${3}
        fi
    else
      answer=y
    fi

    case "${answer}" in
        y|Y|yes|Yes)
            return 0
            ;;
        n|N|no|No)
            return 1
            ;;
        *)
            return 8
            ;;
    esac
}


###############################################################################
# Ask question that should be answered with y/n/a. Return value is dependend on
# answer:
#   y -> 0
#   n -> 1
#   a -> 0
#   c -> exit
#   other -> 8
# If a is entered the variable auto will be set to y
#
# Globals:
#   
# Arguments:
#   question
#   logfile
#
###############################################################################
ask_ynac() {
    answer=n
    if [[ "${auto}" != "y" ]]; then
        log_info "${1} [(y)es/(n)o/(a)uto/(c)ancel]?"
        read -r answer 
        if [[ -n ${2} ]]; then
            print "\n${1} (y/n) : $answer" >>${2}
        fi
    else
      answer=y
    fi

    case "${answer}" in
        y|Y|yes|Yes)
            return 0
            ;;
        a|A|auto|Auto)
            auto="y"
            return 0
            ;;
        n|N|no|No)
            return 1
            ;;
        c|C|cancel|Cancel)
            log_error "Cancel execution of script"
            do_exit 8
            exit 8
            ;;
        *)
            return 8
            ;;
    esac
}

#================================================================
# LOGGING
#================================================================
log() { # $1->level $2->message
    printf "[%s] [%-12.20s] [%-5.5s] %s\\n" "$(k8s_timestamp)" "${prog}" "${1}" "${2}"
}
log_debug() {
    if [[ "${LOGLEVEL}" == "DEBUG" ]]; then
        log "DEBUG" "$@"
    fi
}
log_info() {
    log "INFO" "$@"
}
log_warning() {
    log "WARN" "$@"
}
log_error() {
    log "ERROR" "$@"
}
log_trace() {
    log "TRACE" "$@"
}
logrename ()
{
filecreatedate=`date +%Y%m%d%H%M%S`
 if [ -f $1 ] ;then
   mv $1 $1${filecreatedate}
   log_info "  $1 move to $1${filecreatedate} "
 else
   log_error " $1 not exist "
   exit 16
 fi
}
#================================================================
# packages
#================================================================
isInstalled() {
    if rpm -q $1 &> /dev/null; then
        log_info   "$1 is installed "
        return 1
    else
        log_info   "$1 is not installed"
        return 0
    fi
}