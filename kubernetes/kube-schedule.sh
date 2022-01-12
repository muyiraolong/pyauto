#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy kube-scheduler service
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
#=============================================================================
#  FUNCTIONS
#=============================================================================
if [ $# -gt 0 ]; then
  usage
  exit 8
fi
i=1
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
log_info "  "${LogFile}

source ~/.bash_profile

{
# MASTER_ADDRESS=$1
KUBE_SCHEDULER_OPTS="--kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig --address=127.0.0.1  --cert-dir=${SSL_DIR} --leader-elect=true \
 --logtostderr=false \
 --v=2  \
 --log-dir=${LOG_DIR}/kube-scheduler \
 --client-ca-file=${SSL_DIR}/ca.pem \
 --authentication-kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig \
 --authorization-kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig \
 --requestheader-extra-headers-prefix=X-Remote-Extra- \
 --requestheader-group-headers=X-Remote-Group \
 --requestheader-username-headers=X-Remote-User \
 --requestheader-allowed-names=front-proxy-client"

#--tls-private-key-file=${SSL_DIR}/kube-scheduler.key  this autogenerate by system
#--tls-cert-file=${SSL_DIR}/kube-scheduler.pem \

echo "KUBE_SCHEDULER_OPTS=$KUBE_SCHEDULER_OPTS">${CFG_DIR}/kube-scheduler.conf
log_info "  configure  file kube-scheduler is set as "
log_info "  KUBE_SCHEDULER_OPTS=$KUBE_SCHEDULER_OPTS"
log_info "  Start setup kube-scheduler.service"
cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=network.target network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=-${CFG_DIR}/kube-scheduler.conf
ExecStart=/usr/sbin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat /usr/lib/systemd/system/kube-scheduler.service
log_info "  Setup kube-scheduler.service done"
log_info "  Try to starting  kube-scheduler"
systemctl daemon-reload;systemctl enable kube-scheduler;systemctl restart kube-scheduler
if [ $? -eq 0 ]; then
  log_info "  kube-scheduler is running successfully!"
else
  log_eror "start kube-scheduler failed,pls check in log file /var/log/message"
  log_info "tail -f /var/log/message"
fi
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in ${LogFile}"       | tee -a $LogFile
exit 0

# --address：在 127.0.0.1:10251 端口接收 http /metrics 请求；kube-scheduler 目前还不支持接收 https 请求；
# --kubeconfig：指定 kubeconfig 文件路径，kube-scheduler 使用它连接和验证 kube-apiserver；
# --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；
#
#folowing is v1 version
#KUBE_SCHEDULER_OPTS="--kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig --address=127.0.0.1  --cert-dir=${SSL_DIR} --leader-elect=true \
# --logtostderr=false \
# --v=2  \
# --log-dir=${LOG_DIR}/kube-scheduler \
# --client-ca-file=${SSL_DIR}/ca.pem \"
# mark kube-scheduler.key is autogenerate by k8s.