#!/bin/bash
# MASTER_ADDRESS=$1
KUBE_SCHEDULER_OPTS="--kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig --address=127.0.0.1  --cert-dir=${SSL_DIR} --leader-elect=true \
 --logtostderr=false \
 --v=2  \
 --log-dir=${LOG_DIR}/kube-scheduler"

echo "KUBE_SCHEDULER_OPTS=$KUBE_SCHEDULER_OPTS">${CFG_DIR}/kube-scheduler.conf
cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=network.target network-online.target
Wants=network-online.target
[Service]
EnvironmentFile=-${CFG_DIR}/kube-scheduler.conf
ExecStart=/usr/sbin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload;systemctl enable kube-scheduler;systemctl restart kube-scheduler


# --address：在 127.0.0.1:10251 端口接收 http /metrics 请求；kube-scheduler 目前还不支持接收 https 请求；
# --kubeconfig：指定 kubeconfig 文件路径，kube-scheduler 使用它连接和验证 kube-apiserver；
# --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；