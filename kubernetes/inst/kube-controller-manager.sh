#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy kube-controller-manager.service
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
# MASTER_ADDRESS=$1
{
log_info "  Start generate ${CFG_DIR}/kube-controller-manager.conf"
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \
  --allocate-node-cidrs=true \
  --authentication-kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig \
  --authorization-kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig \
  --v=2 \
  --log-dir=${LOG_DIR}/kube-controller-manager \
  --master=https://${MASTER_ADDRESS}:6443 --leader-elect=true \
  --bind-address=127.0.0.1 \
  --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig \
  --controllers=*,bootstrapsigner,tokencleaner \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=${SSL_DIR}/ca.pem \
  --cluster-signing-key-file=${SSL_DIR}/ca-key.pem  \
  --cluster-cidr=10.244.0.0/16 \
  --cluster-signing-duration=87600h0m0s \
  --client-ca-file=${SSL_DIR}/ca.pem \
  --tls-cert-file=${SSL_DIR}/kube-controller-manager.pem \
  --tls-private-key-file=${SSL_DIR}/kube-controller-manager-key.pem \
  --use-service-account-credentials=true \
  --service-account-private-key-file=${SSL_DIR}/ca-key.pem \
  --service-cluster-ip-range=10.96.0.0/16 \
  --secure-port=10257 \
  --feature-gates=RotateKubeletServerCertificate=true \
  --requestheader-client-ca-file=${SSL_DIR}/ca.pem \
  --requestheader-extra-headers-prefix=X-Remote-Extra- \
  --requestheader-group-headers=X-Remote-Group \
  --requestheader-username-headers=X-Remote-User \
  --requestheader-allowed-names=front-proxy-client \
  --root-ca-file=${SSL_DIR}/ca.pem"

echo "KUBE_CONTROLLER_MANAGER_OPTS="$KUBE_CONTROLLER_MANAGER_OPTS"">${CFG_DIR}/kube-controller-manager.conf
log_info "  Ggenerate ${CFG_DIR}/kube-controller-manager.conf done!!"

log_info "  Start generate /usr/lib/systemd/system/kube-controller-manager.service"
cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=network.target network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=-${CFG_DIR}/kube-controller-manager.conf
ExecStart=/usr/sbin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
log_info "  Generate /usr/lib/systemd/system/kube-controller-manager.service done"

log_info "  Tring to start kube-controller-manager.service"
systemctl daemon-reload;systemctl enable kube-controller-manager;systemctl restart kube-controller-manager
if [ $? -eq 0 ]; then
  log_info "  kube-controller-manager is running successfully!"
else
  log_error "  start kube-controller-manager failed,pls check in log file /var/log/message"
  log_info "  tail -f /var/log/message"
fi
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
exit 0

# --port=0：关闭监听 http /metrics 的请求，同时 --address 参数无效，--bind-address 参数有效；
# --secure-port=10252、--bind-address=0.0.0.0: 在所有网络接口监听 10252 端口的 https /metrics 请求；
# --address：指定监听的地址为127.0.0.1
# --kubeconfig：指定 kubeconfig 文件路径，kube-controller-manager 使用它连接和验证 kube-apiserver；
# --cluster-signing-*-file：签名 TLS Bootstrap 创建的证书；
# --experimental-cluster-signing-duration：指定 TLS Bootstrap 证书的有效期；
# --root-ca-file：放置到容器 ServiceAccount 中的 CA 证书，用来对 kube-apiserver 的证书进行校验；
# --service-account-private-key-file：签名 ServiceAccount 中 Token 的私钥文件，必须和 kube-apiserver 的 --service-account-key-file 指定的公钥文件配对使用；
# --service-cluster-ip-range ：指定 Service Cluster IP 网段，必须和 kube-apiserver 中的同名参数一致；
# --feature-gates=RotateKubeletServerCertificate=true：开启 kublet server 证书的自动更新特性；
# --controllers=*,bootstrapsigner,tokencleaner：启用的控制器列表，tokencleaner 用于自动清理过期的 Bootstrap token；
# --horizontal-pod-autoscaler-*：custom metrics 相关参数，支持 autoscaling/v2alpha1；
# --tls-cert-file、--tls-private-key-file：使用 https 输出 metrics 时使用的 Server 证书和秘钥；
# --use-service-account-credentials=true:
# --allocate-node-cidrs=true  use for flanneld
# --cluster-cidr=10.244.0.0/16 use for flanneld
# --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；