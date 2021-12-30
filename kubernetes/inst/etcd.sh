#!/bin/bash
# example: bash etcd.sh etcd01 192.168.0.101 etcd01=https://192.168.0.101:2380,etcd02=https://192.168.0.102:2380
# ETCD_CLUSTER="win70=https://win70.inno.com:2380,win71=https://win71.inno.com:2380,win72=https://win72.inno.com:2380"
ETCD_NAME=$(hostname -s)
ETCD_IP=$(nslookup $(hostname)|grep -i Address|awk '{print $2}'|grep -v '#')
ETCD_VERSION=3.5.0

cat <<EOF >${CFG_DIR}/etcd.yml
#etcd ${ETCD_VERSION}
name: ${ETCD_NAME}
data-dir: /etc/etcd/data
listen-peer-urls: https://${ETCD_IP}:2380
listen-client-urls: https://${ETCD_IP}:2379,http://127.0.0.1:2379

advertise-client-urls: https://${ETCD_NAME}:2379
initial-advertise-peer-urls: https://${ETCD_NAME}:2380
initial-cluster: ${ETCD_CLUSTER}
initial-cluster-token: etcd-cluster
initial-cluster-state: new
enable-v2: true

client-transport-security:
  cert-file: ${ETCD_SSL_DIR}/server.pem
  key-file: ${ETCD_SSL_DIR}/server-key.pem
  client-cert-auth: true 
  trusted-ca-file: ${ETCD_SSL_DIR}/ca.pem
  auto-tls: true 

peer-transport-security:
  cert-file: ${ETCD_SSL_DIR}/peer.pem
  key-file: ${ETCD_SSL_DIR}/peer-key.pem
  client-cert-auth: true
  trusted-ca-file: ${ETCD_SSL_DIR}/ca.pem
  auto-tls: true

debug: false
logger: zap
log-outputs: [stderr]
EOF

cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
Documentation=https://github.com/etcd-io/etcd
Conflicts=etcd.service
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
LimitNOFILE=65536
Restart=on-failure
RestartSec=5s
TimeoutStartSec=0
ExecStart=/usr/local/etcd/bin/etcd --config-file=/etc/etcd/cfg/etcd.yml

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload;systemctl enable etcd;systemctl restart etcd