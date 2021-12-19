#!/bin/bash
MASTER_ADDRESS=$1
ETCD_SERVERS="https://win70.inno.com:2379,https://win71.inno.com:2379,https://win72.inno.com:2379"
KUBE_APISERVER_OPTS="--logtostderr=false \
    --v=2 --log-dir=/etc/kubernetes/logs/kube-apiserver \
    --etcd-servers=${ETCD_SERVERS} \
    --etcd-cafile=/etc/etcd/ssl/ca.pem \
    --etcd-certfile=/etc/etcd/ssl/client.pem \
    --etcd-keyfile=/etc/etcd/ssl/client-key.pem \
	  --bind-address=0.0.0.0 \
    --secure-port=6443 \
    --advertise-address=${MASTER_ADDRESS} \
    --allow-privileged=true \
    --service-cluster-ip-range=10.96.0.0/16 \
    --enable-aggregator-routing=true \
    --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction \
    --authorization-mode=RBAC,Node \
    --service-node-port-range=30000-50000  \
    --kubelet-client-certificate=/etc/kubernetes/ssl/client.pem \
    --kubelet-client-key=/etc/kubernetes/ssl/client-key.pem \
    --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem  \
    --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
    --client-ca-file=/etc/kubernetes/ssl/ca.pem \
    --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \
    --service-account-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \
    --requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem \
    --requestheader-extra-headers-prefix=X-Remote-Extra- \
    --requestheader-group-headers=X-Remote-Group \
    --requestheader-username-headers=X-Remote-User \
    --runtime-config=api/all=true \
	  --requestheader-allowed-names=''\
	  --proxy-client-key-file=/etc/kubernetes/ssl/client-key.pem \
	  --proxy-client-cert-file=/etc/kubernetes/ssl/client.pem \
    --audit-log-maxage=30 \
    --audit-log-maxbackup=3  \
    --audit-log-maxsize=100 \
    --audit-log-truncate-enabled=true  \
    --audit-log-path=/etc/kubernetes/logs/k8s-audit.log \
    --audit-policy-file=/etc/kubernetes/cfg/audit-policy.yaml \
	  --feature-gates=RemoveSelfLink=false \
    --anonymous-auth=false"

echo "KUBE_APISERVER_OPTS=$KUBE_APISERVER_OPTS">/etc/kubernetes/cfg/kube-apiserver.conf
export KUBE_APISERVER_OPTS
cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Documentation=https://github.com/kubernetes/kubernetes
Description=Kubernetes:Apiserver
After=network.target network-online.target
Wants=network-online.target
[Service]
RestartSec=5
Restart=on-failure
EnvironmentFile=-/etc/kubernetes/cfg/kube-apiserver.conf
ExecStart=/usr/sbin/kube-apiserver \$KUBE_APISERVER_OPTS
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable kube-apiserver && systemctl restart kube-apiserver

#--authorization-mode=Node,RBAC： 开启 Node 和 RBAC 授权模式，拒绝未授权的请求；
#--enable-admission-plugins：启用 ServiceAccount 和 NodeRestriction；
#--service-account-key-file：签名 ServiceAccount Token 的公钥文件，kube-controller-manager 的 --service-account-private-key-file 指定私钥文件，两者配对使用；
#--tls-*-file：指定 apiserver 使用的证书、私钥和 CA 文件。--client-ca-file 用于验证 client (kue-controller-manager、kube-scheduler、kubelet、kube-proxy 等)请求所带的证书；
#--kubelet-client-certificate、--kubelet-client-key：如果指定，则使用 https 访问 kubelet APIs；需要为证书对应的用户(上面 kubernetes*.pem 证书的用户为 kubernetes) 用户定义 RBAC 规则，否则访问 kubelet API 时提示未授权；
#--bind-address： 不能为 127.0.0.1，否则外界不能访问它的安全端口 6443；
#--insecure-port=0：关闭监听非安全端口(8080)；
#--service-cluster-ip-range： 指定 Service Cluster IP 地址段；
#--service-node-port-range： 指定 NodePort 的端口范围；
#--runtime-config=api/all=true： 启用所有版本的 APIs，如 autoscaling/v2alpha1；
#--enable-bootstrap-token-auth：启用 kubelet bootstrap 的 token 认证；
#--apiserver-count=3：指定集群运行模式，多台 kube-apiserver 会通过 leader 选举产生一个工作节点，其它节点处于阻塞状态；
#kubelet-port not using here
#--service-cluster-ip-rang					  address using for service
#--allow-privileged       					  If true, allow privileged containers. [default=false]
#--master is not using
#--apiserver-count int					      The number of apiservers running in the cluster, must be a positive number. \
#												(In use when --endpoint-reconciler-type=master-count is enabled.) (default 1)
#--endpoint-reconciler-type string             Use an endpoint reconciler (master-count, lease, none) (default "lease")		
#--kubelet-preferred-address-types strings     List of the preferred NodeAddressTypes to use for kubelet connections. \
# 		     									(default [Hostname,InternalDNS,InternalIP,ExternalDNS,ExternalIP])	