#!/bin/bash
NODE_ADDRESS=$1

#kubeadm config print init-defaults --component-configs KubeletConfiguration >kubelet.yml generate kubelet.yml
cat <<EOF >/etc/kubernetes/cfg/kubelet.yaml
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
tlsCertFile: /etc/kubernetes/ssl/kubelet.pem
tlsPrivateKeyFile: /etc/kubernetes/ssl/kubelet-key.pem
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/ssl/ca.pem
# 授权
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
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

KUBELET_OPTS="--kubeconfig=/etc/kubernetes/cfg/kubelet.kubeconfig \
   --runtime-cgroups=/systemd/system.slice \
   --config=/etc/kubernetes/cfg/kubelet.yaml \
   --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 \
   --logtostderr=false \
   --v=2 \
   --log-dir=/etc/kubernetes/logs/kubelet"
echo "KUBELET_OPTS=$KUBELET_OPTS">/etc/kubernetes/cfg/kubelet.conf

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-/etc/kubernetes/cfg/kubelet.conf
ExecStart=/usr/sbin/kubelet \$KUBELET_OPTS 
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload;systemctl enable kubelet;systemctl restart kubelet