#!/bin/bash
# HEADER
#================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    setup kubernetes kubelet services
#%
#% ARGUMENTS
#%     use hostname as default
#%
#% EXAMPLES
#%    ${prog}
#%
#================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#================================================================
#  NOTES
#================================================================
# END_OF_HEADER
#================================================================

#================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#================================================================
#  FUNCTIONS
#================================================================
do_exit() {
  RC=$1
  echo "$RC" >/tmp/RC.$$
  exit $RC
}




if [ $# -gt 0 ]; then
  usage
  exit 8
fi
RC=0
scriptname=$(basename $0)
starttime=$(date +%s)
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

. ${RUNDIR}/master-slave.sh

#================================================================
#  Main
#================================================================
NODE_ADDRESS=$(hostname)
{
log_info "  Generate kubelet configure file ${CFG_DIR}/kubelet.conf "

if [ -f /workdata/kubelet/${NODE_ADDRESS} ];then
   log_info "/workdata/kubelet/${NODE_ADDRESS}  is exist"
   systemctl stop kubelet
   rm -rf /workdata/kubelet/${NODE_ADDRESS}
fi
mkdir /workdata/kubelet/${NODE_ADDRESS} -p
log_info "  /workdata/kubelet/${NODE_ADDRESS}  is create"

KUBELET_OPTS="--kubeconfig=${CFG_DIR}/kubelet.kubeconfig \
   --runtime-cgroups=/systemd/system.slice \
   --config=${CFG_DIR}/kubelet.yaml \
   --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 \
   --logtostderr=false \
   --v=2 \
   --log-dir=${LOG_DIR}/kubelet \
   --root-dir=/workdata/kubelet/${NODE_ADDRESS}"

# --container-runtime=remote
# --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock
# --image-pull-progress-deadline=2m
# --network-plugin=cni
# --register-node=true

echo "KUBELET_OPTS=$KUBELET_OPTS">${CFG_DIR}/kubelet.conf
log_info "  Generate kubelet configure file ${CFG_DIR}/kubelet.conf done "

log_info "  Generate ${CFG_DIR}/kubelet.yaml "

#kubeadm config print init-defaults --component-configs KubeletConfiguration >kubelet.yml generate kubelet.yml
cat <<EOF >${CFG_DIR}/kubelet.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
hostnameOverride: ${NODE_ADDRESS}
port: 10250
readOnlyPort: 10255
cgroupDriver: systemd
kubeletCgroups: /systemd/system.slice
clusterDNS:
  - 10.96.0.10
clusterDomain: cluster.local.
healthzBindAddress: 127.0.0.1
healthzPort: 10248
failSwapOn: false
# 身份验证
tlsCertFile: ${SSL_DIR}/kubelet.pem
tlsPrivateKeyFile: ${SSL_DIR}/kubelet-key.pem
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: ${SSL_DIR}/ca.pem
# 授权
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
enforceNodeAllocatable:
- pods
kubeReserved:
  cpu: 500m
  memory: 1Gi
  ephemeral-storage: 1Gi
systemReserved:
  memory: 1Gi
evictionHard:
  imagefs.available: "15%"
  memory.available: "300Mi"
  nodefs.available: "10%"
  nodefs.inodesFree: "5%"
rotateCertificates: true
maxOpenFiles: 1000000
maxPods: 110
HairpinMode: hairpin-veth
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
logging: {}
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
EOF
log_info "  Generate ${CFG_DIR}/kubelet.yaml done"

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-${CFG_DIR}/kubelet.conf
ExecStart=/usr/sbin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload;systemctl enable kubelet;systemctl start kubelet
if [ $? -eq 0 ]; then
  log_info "  Start  kubelet successfully!!"
  sleep 10
  kubectl get nodes && kubectl get csr
else
  log_error "start kubelet failed,pls check in log file /var/log/message"
  log_error "tail -f /var/log/message"
  do_exit 8
fi
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