#!/bin/bash
NODE_ADDRESS=$(hostname)
if ! [ -d /etc/kubernetes/manifests ]; then
   mkdir /etc/kubernetes/manifests
fi
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
if ! [ -d /workdata/kubelet/${NODE_ADDRESS} ] ;then
	mkdir /workdata/kubelet/${NODE_ADDRESS} -p
else
    echo "delete the old kubelet root file"
	rm -rf /workdata/kubelet/${NODE_ADDRESS}
	mkdir /workdata/kubelet/${NODE_ADDRESS} -p
fi

KUBELET_OPTS="--kubeconfig=${CFG_DIR}/kubelet.kubeconfig \
   --runtime-cgroups=/systemd/system.slice \
   --config=${CFG_DIR}/kubelet.yaml \
   --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 \
   --logtostderr=false \
   --v=2 \
   --log-dir=${LOG_DIR}/kubelet \
   --root-dir=/workdata/kubelet/${NODE_ADDRESS}"
echo "KUBELET_OPTS=$KUBELET_OPTS">${CFG_DIR}/kubelet.conf

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
## service file need to change
systemctl daemon-reload;systemctl enable kubelet;systemctl restart kubelet