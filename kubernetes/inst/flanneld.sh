#!/bin/bash
#=============================================================================
# HEADER
#=============================================================================
#% SYNOPSIS
#%    ${prog}
#%
#% DESCRIPTION
#%    Script to deploy flanneld service
#%
#% ARGUMENTS
#%    NONE
#%
#% EXAMPLES
#%    ${prog}
#%
#=============================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#=============================================================================
#  NOTES
#=============================================================================
# END_OF_HEADER
#=============================================================================

#=============================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#=============================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#=============================================================================
#  FUNCTIONS
#=============================================================================
if [ $# -gt 0 ]; then
  usage
  exit 8
fi
i=1
scriptname=$(basename $0)
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

source ~/.bash_profile

systemctl stop flanneld;
{
if [ ${#ETCD_NODE_NAMES_DOMAIN[@]} -eq 1 ]; then
  echo "Configure standalone ETCD_SERVERS for flanneld"
  ETCD_SERVERS=${ETCD_SERVERS},http://127.0.0.1:2379
fi

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
if [ $? -eq 0 ]; then
  echo  "  Flanneld is running successfully!"
else
  echo "  start Flanneld,pls check in log file /var/log/message"
  echo "  tail -f /var/log/message"
fi
} 2>&1 | tee -a $LogFile

log_info  "  OK: EndofScript ${scriptname} " | tee -a $LogFile
log_info  "  Save log in   ${LogFile}"       | tee -a $LogFile
exit 0
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
