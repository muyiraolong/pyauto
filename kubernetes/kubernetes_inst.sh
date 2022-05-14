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
log_info "Start install kubernetes"
mywget https://dl.k8s.io/v1.22.4/kubernetes-server-linux-amd64.tar.gz
tar -xvf ${RUNDIR}/kubernetes-server-linux-amd64.tar.gz 
cp -p ${RUNDIR}/kubernetes/server/bin/{kubectl,kube-apiserver,kube-controller-manager,kube-scheduler,kube-proxy,kubelet} /usr/sbin
sh ${RUNDIR}/xsync -d /usr/sbin/kubectl
sh ${RUNDIR}/xsync -d /usr/sbin/kube-apiserver
sh ${RUNDIR}/xsync -d /usr/sbin/kube-controller-manager
sh ${RUNDIR}/xsync -d /usr/sbin/kube-scheduler
sh ${RUNDIR}/xsync -d /usr/sbin/kube-proxy
sh ${RUNDIR}/xsync -d /usr/sbin/kubelet

if [ $? -eq 0 ]; then
  log_info "kubernetes install with version $(echo "https://dl.k8s.io/v1.24.0/kubernetes-server-linux-amd64.tar.gz"|cut -d '/' -f 4) successfully"
fi
echo;echo
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
logrename  ${LogFile}
exit 0
