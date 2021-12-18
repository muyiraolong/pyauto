#!/bin/bash
MASTER_ADDRESS=$1
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \
--v=2 \
--log-dir=/etc/kubernetes/logs/kube-controller-manager \
--master=https://${MASTER_ADDRESS}:6443 --leader-elect=true \
--secure-port=10257 --bind-address=127.0.0.1 --controllers=*,bootstrapsigner,tokencleaner \
--kubeconfig=/etc/kubernetes/cfg/kube-controller-manager.kubeconfig \
--service-cluster-ip-range=10.96.0.0/16 \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  \
--tls-cert-file=/etc/kubernetes/ssl/kube-controller-manager.pem \
--tls-private-key-file=/etc/kubernetes/ssl/kube-controller-manager-key.pem \
--use-service-account-credentials=true \
--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \
--cluster-signing-duration=87600h0m0s \
--feature-gates=RotateKubeletServerCertificate=true \
--allocate-node-cidrs=true \
--cluster-cidr=10.244.0.0/16 \
--root-ca-file=/etc/kubernetes/ssl/ca.pem"

echo "KUBE_CONTROLLER_MANAGER_OPTS=$KUBE_CONTROLLER_MANAGER_OPTS">/etc/kubernetes/cfg/kube-controller-manager.conf
cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=network.target network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=-/etc/kubernetes/cfg/kube-controller-manager.conf
ExecStart=/usr/sbin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload;systemctl enable kube-controller-manager;systemctl restart kube-controller-manager

# --port=0：关闭监听 http /metrics 的请求，同时 --address 参数无效，--bind-address 参数有效；
# --secure-port=10252、--bind-address=0.0.0.0: 在所有网络接口监听 10252 端口的 https /metrics 请求；
# --address：指定监听的地址为127.0.0.1
# --kubeconfig：指定 kubeconfig 文件路径，kube-controller-manager 使用它连接和验证 kube-apiserver；
# --cluster-signing-*-file：签名 TLS Bootstrap 创建的证书；
# --experimental-cluster-signing-duration：指定 TLS Bootstrap 证书的有效期；
# --root-ca-file：放置到容器 ServiceAccount 中的 CA 证书，用来对 kube-apiserver 的证书进行校验；
# --service-account-private-key-file：签名 ServiceAccount 中 Token 的私钥文件，必须和 kube-apiserver 的 --service-account-key-file 指定的公钥文件配对使用；
# --service-cluster-ip-range ：指定 Service Cluster IP 网段，必须和 kube-apiserver 中的同名参数一致；
# --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；
# --feature-gates=RotateKubeletServerCertificate=true：开启 kublet server 证书的自动更新特性；
# --controllers=*,bootstrapsigner,tokencleaner：启用的控制器列表，tokencleaner 用于自动清理过期的 Bootstrap token；
# --horizontal-pod-autoscaler-*：custom metrics 相关参数，支持 autoscaling/v2alpha1；
# --tls-cert-file、--tls-private-key-file：使用 https 输出 metrics 时使用的 Server 证书和秘钥；
# --use-service-account-credentials=true:
# --allocate-node-cidrs=true  use for flanneld
# --cluster-cidr=10.244.0.0/16 use for flanneld