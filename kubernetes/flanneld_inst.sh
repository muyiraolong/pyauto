#!/usr/bin/ksh
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy etcd service
#%
#% ARGUMENTS
#%    NONE
#%
#% EXAMPLES
#%    ${prog}
#%
#=============================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#=============================================================================
#  NOTES
#=============================================================================
# END_OF_HEADER
#=============================================================================

#=============================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#=============================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#=============================================================================
#  FUNCTIONS
#=============================================================================
# example: bash etcd.sh etcd01 192.168.0.101 etcd01=https://192.168.0.101:2380,etcd02=https://192.168.0.102:2380
# ETCD_CLUSTER="win70=https://win70.inno.com:2380,win71=https://win71.inno.com:2380,win72=https://win72.inno.com:2380"

#######################################################################################################################
## MAIN
#######################################################################################################################
if [ $# -gt 0 ]; then
  usage
  exit 8
fi

source ~/.bash_profile

scriptname=$(basename $0)

if ! [ -f ${LOG_FILE_DIR}/${scriptname}.log  ];then
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
else
  rm -rf ${LOG_FILE_DIR}/${scriptname}.log
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
fi
export LogFile=${LOG_FILE_DIR}/${scriptname}.log
echo ${LogFile}

{
log_info "   Start  install flanneld"
mywget https://github.com/flannel-io/flannel/releases/download/v0.15.1/flannel-v0.15.1-linux-amd64.tar.gz

tar -xvf ${RUNDIR}/flannel-v0.15.1-linux-amd64.tar.gz -C /usr/sbin/

sh ${RUNDIR}/xsync -d /usr/sbin/flanneld
sh ${RUNDIR}/xsync -d /usr/sbin/mk-docker-opts.sh

if flanneld -version ; then
  echo
  log_info "   flanneld install with version $(flanneld -version) successfully"
else 
  log_error "   Flanneld install failed"   
  do_exit 8
  echo 
fi
echo;echo
} 2>&1 | tee -a $LogFile

if [ -f /tmp/RC.$$ ]; then
   RC=$(cat /tmp/RC.$$)
   rm -f /tmp/RC.$$
fi
if [ "$RC" == "0" ]; then
  log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
else
  log_error  "  ERROR: EndofScript ${scriptname} " | tee -a $LogFile
fi
ende=$(date +%s)
diff=$((ende - starttime))
log_info  "  $(date)   Runtime      :   $diff" | tee -a $LogFile
log_info  "  Save log to ${LogFile}             "  | tee -a $LogFile
logrename  ${LogFile}
exit ${RC}
