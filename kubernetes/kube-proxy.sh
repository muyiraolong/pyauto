#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy kube-apiservice service
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
echo ${LogFile}
source ~/.bash_profile

{
NODE_ADDRESS=$(hostname)
log_info "  Create kube-proxy config yaml file"
# kubeadm configprint init-defaults --component-configs KubeProxyConfiguration >kube-proxy.conf
cat <<EOF >${CFG_DIR}/kube-proxy.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: ${CFG_DIR}/kube-proxy.kubeconfig
  qps: 0
clusterCIDR: 10.244.0.0/16
configSyncPeriod: 15m0s
conntrack:
  maxPerCore: 32768
  min: 131072
  tcpCloseWaitTimeout: 1h0m0s
  tcpEstablishedTimeout: 24h0m0s
enableProfiling: false
hostnameOverride: ${NODE_ADDRESS} 
healthzBindAddress: 0.0.0.0:10256
metricsBindAddress: 0.0.0.0:10249
mode: ipvs
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: "rr"
  strictARP: false
  syncPeriod: 0s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s  
EOF
log_info "  kube-proxy config yaml file is created"
export KUBE_PROXY_OPTS="--logtostderr=false --v=2 --log-dir=${LOG_DIR}/kube-proxy --config=${CFG_DIR}/kube-proxy.yaml"
echo "KUBE_PROXY_OPTS=$KUBE_PROXY_OPTS">/etc/kubernetes/cfg/kube-proxy.conf
log_info "  kube-proxy config file is /etc/kubernetes/cfg/kube-proxy.conf"

log_info "  Create kube-proxy service"
cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-${CFG_DIR}/kube-proxy.conf
ExecStart=/usr/sbin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
log_info  "  kube-proxy service is created"


log_info  "  Tring to start kube-proxy service"
systemctl daemon-reload;systemctl enable kube-proxy;systemctl restart kube-proxy
#SupportIPVSProxyMode：if not work ,remove this line
#clusterCIDR 后面CNI网络的IP段，不能与任何网络重复，否则获报错

systemctl daemon-reload;systemctl enable kubelet;systemctl restart kubelet
if [ $? -eq 0 ]; then
  log_info "  kube-proxy is running successfully!"
else
  log_error "Start kube-proxy failed,pls check in log file /var/log/message "
  log_info  "${LOG_DIR}"
fi
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
exit 0