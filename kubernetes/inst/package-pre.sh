#!/bin/bash
yum -y install ipvsadm.x86_64 conntrack-tools 
cat <<EOF >ipvs.sh
modprobe -- ip_vs
modprobe -- ip_vs_sh
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- nf_conntrack_ipv4
EOF
chmod +x ipvs.sh
bash ipvs.sh
lsmod |grep ip_vs
echo "ipvs.sh" >>/etc/rc.local
chmod +x /etc/rc.local
cat <<EOF >/etc/sysctl.d/k8s.conf
#sysctls for k8s node config
kernel.softlockup_all_cpu_backtrace=1
kernel.softlockup_panic=1
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=16384
fs.file-max=52706963
fs.nr_open=52706963
fs.inotify.max_user_watches=524288
fs.may_detach_mounts=1
vm.max_map_count=262144
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
net.core.netdev_max_backlog=16384
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.somaxconn=32768
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=8096
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_wmem=4096 12582912 16777216
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
sysctl -p /etc/sysctl.d/k8s.conf
#关闭swap
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
#关闭selinux
setenforce 0 && sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

yum install ipset ipvsadm -y
#设置 rsyslogd 和 systemd journald
mkdir /var/log/journa
mkdir -p  /etc/systemd/journald.conf.d/

cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
# 持久化保存到磁盘
Storage=persistent
# 压缩历史日志
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
# 最大占用空间 10G
SystemMaxUse=10G
# 单日志文件最大 200M
SystemMaxFileSize=200M
# 日志保存时间 2 周
MaxRetentionSec=2week
# 不将日志转发到 syslog
ForwardToSyslog=no
EOF
systemctl restart systemd-journald