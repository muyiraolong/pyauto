#!/bin/bash
NODE_ADDRESS=$1

cat <<EOF >/etc/kubernetes/cfg/kube-proxy.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: /etc/kubernetes/cfg/kube-proxy.kubeconfig
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

export KUBE_PROXY_OPTS="--logtostderr=false --v=2 --log-dir=/etc/kubernetes/logs/kube-proxy --config=/etc/kubernetes/cfg/kube-proxy.yaml"
echo "KUBE_PROXY_OPTS=$KUBE_PROXY_OPTS">/etc/kubernetes/cfg/kube-proxy.conf

cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/cfg/kube-proxy.conf
ExecStart=/usr/sbin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload;systemctl enable kube-proxy;systemctl restart kube-proxy

#SupportIPVSProxyMode：if not work ,remove this line
#clusterCIDR 后面CNI网络的IP段，不能与任何网络重复，否则获报错
