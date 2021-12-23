#!/bin/bash

FLANNEL_OPTIONS="--etcd-cafile=/etc/kubernetes/ssl/ca.pem \
   --etcd-certfile=/etc/kubernetes/ssl/flanneld.pem \
   --etcd-keyfile=/etc/kubernetes/ssl/flanneld-key.pem \
   --etcd-endpoints=win70=https://win70.inno.com:2379,win71=https://win71.inno.com:2379,win72=https://win72.inno.com:2379 \
   --etcd-prefix=/atomic.io/network \
   --iface=ens224 \
   --ip-masq"
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
   
Restart=always
RestartSec=5
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF

systemctl daemon-reload;systemctl start flanneld;systemctl enable flanneld;systemctl status flanneld
/usr/local/mk-docker-opts.sh -c
cp -p /run/docker_opts.env /etc/kubernetes/flanneld/
systemctl daemon-reload ;systemctl restart docker;systemctl status docker