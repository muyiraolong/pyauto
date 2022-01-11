#!/bin/bash
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
i=1
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


export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/local/etcd/bin
{
ETCD_NAME=$(hostname -s)
ETCD_IP=$(nslookup $(hostname)|grep -i Address|awk '{print $2}'|grep -v '#')
ETCD_VERSION=3.5.0
ps -ef|grep -i etcd
if [ $? -eq 0 ]; then
  systemctl stop etcd
fi
log_info "  Delete old etcd file "
rm -rf /etc/etcd/data/*
if [ $? -eq 0 ]; then
  systemctl stop etcd
fi
log_info "  Old etcd file is deleted "
if [ -f ${ETCD_CFG_DIR}/etcd.yml ] ;then
  log_info "  ${ETCD_CFG_DIR}/etcd.yml exist,delete!"
  rm -rf ${ETCD_CFG_DIR}/etcd.yml
fi
log_info "  Generate ${ETCD_CFG_DIR}/etcd.yml"
if [ $(hostname) != ${MASTERNODE} ];then
  log_info "  Update certification from master"
  scp -rp ${MASTERNODE}:${ETCD_SSL_DIR}/* ${ETCD_SSL_DIR}
  scp -rp ${MASTERNODE}:${SSL_DIR}/* ${SSL_DIR}
  log_info "  Update certification from master done"
fi
cat <<EOF >${ETCD_CFG_DIR}/etcd.yml
#etcd ${ETCD_VERSION}
name: ${ETCD_NAME}
data-dir: /etc/etcd/data
listen-peer-urls: https://${ETCD_IP}:2380
listen-client-urls: https://${ETCD_IP}:2379,http://127.0.0.1:2379

advertise-client-urls: https://${ETCD_NAME}:2379
initial-advertise-peer-urls: https://${ETCD_NAME}:2380
initial-cluster: ${ETCD_CLUSTER}
initial-cluster-token: etcd-cluster
initial-cluster-state: new
enable-v2: true

client-transport-security:
  cert-file: ${ETCD_SSL_DIR}/server.pem
  key-file: ${ETCD_SSL_DIR}/server-key.pem
  client-cert-auth: true 
  trusted-ca-file: ${ETCD_SSL_DIR}/ca.pem
  auto-tls: true 

peer-transport-security:
  cert-file: ${ETCD_SSL_DIR}/peer.pem
  key-file: ${ETCD_SSL_DIR}/peer-key.pem
  client-cert-auth: true
  trusted-ca-file: ${ETCD_SSL_DIR}/ca.pem
  auto-tls: true

debug: false
logger: zap
log-outputs: [stderr]
EOF
log_info " ${ETCD_CFG_DIR}/etcd.yml generated as below:"
cat   ${ETCD_CFG_DIR}/etcd.yml
log_info " Generate etcd.service file "
cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
Documentation=https://github.com/etcd-io/etcd
Conflicts=etcd.service
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
LimitNOFILE=65536
Restart=on-failure
RestartSec=5s
TimeoutStartSec=0
ExecStart=/usr/local/etcd/bin/etcd --config-file=/etc/etcd/cfg/etcd.yml

[Install]
WantedBy=multi-user.target
EOF
} 2>&1 | tee -a $LogFile
log_info "  Start etcd.service......"

{
systemctl daemon-reload;systemctl enable etcd;systemctl restart etcd
if [ $? -eq 0 ]; then
  log_info "  ETCD is running successfully! \n"
else
  log_info "  start etcd,pls check in log file /var/log/message"
  log_info "  tail -f /var/log/message"
fi
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
exit 0