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
log_info "Start  install GOLANG"
while true
  do
    sleep 5
    wget https://go.dev/dl/go1.16.10.linux-amd64.tar.gz
    if [ $? -eq 0 ]; then
      log_info "download https://go.dev/dl/go1.16.10.linux-amd64.tar.gz successfully."
      break;
    fi
  done

tar -xvf ${RUNDIR}/go1.16.10.linux-amd64.tar.gz -C /usr/local
chown root:root -R /usr/local/go
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bash_profile
. ~/.bash_profile
go version
if [ $? -eq 0 ]; then
  log_info "GOLANG install successfully"
fi

log_info "Start install etcd"
while true
  do
    sleep 5
    wget https://github.com/etcd-io/etcd/archive/v3.5.0.zip
    if [ $? -eq 0 ]; then
      log_info "download https://github.com/etcd-io/etcd/archive/v3.5.0.zip successfully."
    break;
    fi
  done
unzip ${RUNDIR}/v3.5.0.zip -d /usr/local
mv /usr/local/etcd-3.5.0 /usr/local/etcd
echo "export PATH=\$PATH:/usr/local/etcd/bin" >> ~/.bash_profile
. ~/.bash_profile
cd /usr/local/etcd/ && ./build.sh
cd ${RUNDIR}

if [ $? -eq 0 ]; then
  log_info "etcd install successfully"
  etcd --version
fi
} 2>&1 | tee -a $LogFile

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/etcd/bin

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
logrename  ${LogFile}
exit 0
