#!/bin/bash
export ETCDCTL_API=2
certs="--ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/flanneld.pem --key-file=/etc/kubernetes/ssl/flanneld-key.pem"
endpoint="--endpoints=https://win70.inno.com:2379,https://win71.inno.com:2379,https://win72.inno.com:2379"
#etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16", "SubnetLen": 16,"Backend": {"Type": "vxlan"}}'
etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16","Backend": {"Type": "vxlan"}}'
etcdctl $certs $endpoint get /atomic.io/network/config 

FLANNEL_OPTIONS="--etcd-cafile=/etc/kubernetes/ssl/ca.pem \
   --etcd-certfile=/etc/kubernetes/ssl/flanneld.pem \
   --etcd-keyfile=/etc/kubernetes/ssl/flanneld-key.pem \
   --etcd-endpoints=win70=https://win70.inno.com:2379,win71=https://win71.inno.com:2379,win72=https://win72.inno.com:2379 \
   --etcd-prefix=/atomic.io/network \
   --iface=ens224 \
   --ip-masq"
echo "FLANNEL_OPTIONS=$FLANNEL_OPTIONS">/etc/sysconfig/flanneld
cat >/usr/lib/systemd/system/flanneld.service <<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
ExecStart=/usr/sbin/flanneld \$FLANNEL_OPTIONS
   
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF
systemctl daemon-reload;systemctl start flanneld;systemctl enable flanneld;systemctl status flanneld
systemctl start flanneld;systemctl status flanneld

for i in 70 71 72 73; do scp -p /mnt/hgfs/kubernetes/1_bink8sinst/flanneld/flanneld win$i:/etc/sysconfig/flanneld; done
for i in 70 71 72 73; do scp -p /mnt/hgfs/kubernetes/1_bink8sinst/kubeconfig/flanneld.service win$i:/usr/lib/systemd/system/flanneld.service; done
cp /usr/lib/systemd/system/flanneld.service   /mnt/hgfs/kubernetes/package/k8s/kubeconfig/
cp -p /usr/lib/systemd/system/flanneld.service /mnt/hgfs/kubernetes/package/k8s/kubeconfig/


/usr/local/mk-docker-opts.sh -c
cp -p /run/docker_opts.env /etc/kubernetes/flanneld/
for i in 70 71 72 73; do scp -p /mnt/hgfs/kubernetes/1_bink8sinst/flannel/mk-docker-opts.sh win$i:/usr/local/mk-docker-opts.sh; done
cat /run/docker_opts.env 
DOCKER_OPTS=" --bip=10.244.27.1/24 --ip-masq=false --mtu=1450"

for i in 70 71 72 73 ;do scp -p /mnt/hgfs/kubernetes/1_bink8sinst/kubeconfig/docker.service win$i:/lib/systemd/system/docker.service;done
/usr/local/mk-docker-opts.sh -c;
systemctl daemon-reload ;systemctl restart docker;systemctl status docker