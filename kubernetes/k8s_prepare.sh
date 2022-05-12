#!/bin/bash
# HEADER
#================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    setup kubernetes kubelet services
#%
#% ARGUMENTS
#%     use hostname as default
#%
#% EXAMPLES
#%    ${prog}
#%
#================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#================================================================
#  NOTES
#================================================================
# END_OF_HEADER
#================================================================

#================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#================================================================
#  FUNCTIONS
#================================================================
do_exit() {
  RC=$1
  echo "$RC" >/tmp/RC.$$
  exit $RC
}

if [ $# -gt 0 ]; then
  usage
  exit 8
fi
RC=0
scriptname=$(basename $0)
starttime=$(date +%s)
if ! [ -f ${LOG_FILE_DIR}/${scriptname}.log  ];then
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
else
  rm -rf ${LOG_FILE_DIR}/${scriptname}.log
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
fi
export LogFile=${LOG_FILE_DIR}/${scriptname}.log
echo ${LogFile}

{
log_info "========================================================="
log_info "install ipset ipvsadm.x86_64 conntrack-tools"
yum -y install ipset ipvsadm.x86_64 conntrack-tools
if [ $? -eq 0 ]; then
   log_info "install ipset ipvsadm.x86_64 conntrack-tools done"
fi
# enable ipvs
log_info "start enable ipvs"
cat <<EOF >/etc/sysconfig/modules/ipvs.sh
modprobe -- ip_vs
modprobe -- ip_vs_sh
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- nf_conntrack_ipv4
#modprobe br_netfilter
EOF
chmod +x /etc/sysconfig/modules/ipvs.sh
bash /etc/sysconfig/modules/ipvs.sh
lsmod |grep -e ip_vs -e nf_conntrack_ipv4

echo "ipvs.sh" >>/etc/rc.local
chmod +x /etc/rc.local
log_info "start enable ipvs done"

log_info "start setup sysconfigure"
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

timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
systemctl restart rsyslog
systemctl restart crond

sysctl -p /etc/sysctl.d/k8s.conf
log_info "start setup sysconfigure"
#关闭swap
log_info "start disable swap"
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
log_info "disable swap done"
#关闭selinux
log_info "start disable selinux"
setenforce 0 && sed -i 's/=enforcing/=disabled/g' /etc/selinux/config
log_info "Disable selinux done"
#关闭numa
log_info "start disable numa"
sed -i 's/quiet/quiet numa=off/g' /etc/default/grub
grub2-mkconfig -o /etc/grub2.cfg
log_info "disable numa done"
#reboot

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
} 2>&1 | tee -a $LogFile

if [ -f /tmp/RC.$$ ]; then
   RC=$(cat /tmp/RC.$$)
   rm -f /tmp/RC.$$
fi
if [ "$RC" == "0" ]; then
  log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
else
  log_error  "  ERROR: EndofScript ${scriptname} " | tee -a $LogFile
fi
ende=$(date +%s)
diff=$((ende - starttime))
log_info  "  $(date)   Runtime      :   $diff" | tee -a $LogFile
log_info  "  Save log to ${LogFile}             "  | tee -a $LogFile
logrename  ${LogFile}
exit ${RC}