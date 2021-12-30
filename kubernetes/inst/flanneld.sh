#!/bin/bash
systemctl stop flanneld;
FLANNEL_OPTIONS="--etcd-cafile=${SSL_DIR}/ca.pem \
   --etcd-certfile=${SSL_DIR}/flanneld.pem \
   --etcd-keyfile=${SSL_DIR}/flanneld-key.pem \
   --etcd-endpoints=${ETCD_SERVERS} \
   --etcd-prefix=/atomic.io/network \
   --iface=ens224 \
   --ip-masq"
if ! [ -d /etc/kubernetes/flanneld ]; then
    mkdir /etc/kubernetes/flanneld
fi

echo "FLANNEL_OPTIONS=$FLANNEL_OPTIONS">/etc/sysconfig/flanneld
cat <<EOF >/usr/lib/systemd/system/flanneld.service
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
ExecStartPost=/usr/local/mk-docker-opts.sh -k DOCKER_OPTS -d /etc/kubernetes/flanneld/docker_opts.env
   
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF

systemctl daemon-reload;systemctl start flanneld;systemctl enable flanneld;systemctl status flanneld
# /usr/local/mk-docker-opts.sh -c
# cp -p /run/docker_opts.env /etc/kubernetes/flanneld/
# systemctl daemon-reload ;systemctl restart docker;systemctl status docker


# FLANNEL_OPTIONS="--etcd-cafile=/etc/kubernetes/ssl/ca.pem \
   # --etcd-certfile=/etc/kubernetes/ssl/flanneld.pem \
   # --etcd-keyfile=/etc/kubernetes/ssl/flanneld-key.pem \
   # --etcd-endpoints=win72=https://win72.inno.com:2379 \
   # --etcd-prefix=/atomic.io/network \
   # --iface=ens224 \
   # --ip-masq"
