#!/bin/bash
#
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#%    ${prog} st|ms|cl
#%
#% DESCRIPTION
#%    build kubernetes  in three mode
#%
#%          standalone:   one host with all funcation
#%          masterslave:  master and backup
#%          cluster:      kubernetes cluaster more thatn one master and work nodes
#%
#% ARGUMENTS
#%     st ---> standalone
#%     ms ---> masterslave
#%     cl ---> cluster
#%
#% EXAMPLES
#%    ${prog} st
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

if [ $# -gt 1 ]; then
  usage
  exit 8
fi


# init running env
standalone()
{
  cp -p ${RUNDIR}/standalone.sh ~
  log_info "  Start build kubernetes standalone"
  echo "if [ -f ~/standalone.sh ]; then "   >> ~/.bash_profile
  echo "    . ~/standalone.sh"              >> ~/.bash_profile
  echo "fi"                                 >> ~/.bash_profile
  source  ~/.bash_profile
  sh ${RUNDIR}/k8s-prepare.sh
  sh ${RUNDIR}/cfssl_inst.sh
  sh ${RUNDIR}/gencert.sh
  sh ${RUNDIR}/etcd_inst.sh
  sh ${RUNDIR}/etcd.sh
  sh ${RUNDIR}/flanneld_inst.sh
  flanneld_network_init
  sh ${RUNDIR}/flanneld.sh
  sh ${RUNDIR}/docker.sh
  sh ${RUNDIR}/kubernetes_inst.sh
  sh ${RUNDIR}/kubeconfig.sh 
  sh ${RUNDIR}/kube-apiserver.sh
  sh ${RUNDIR}/kube-controller-manager.sh
  sh ${RUNDIR}/kube-schedule.sh
  sh ${RUNDIR}/kube-proxy.sh
  sh ${RUNDIR}/kubelet.sh
  kcheck
}

masterslave()
{ 
  cp -p ${RUNDIR}/{*.sh,*.py,*.ksh} ~
  cp -p ${RUNDIR}/xsync ~
  sh xsync ~/check_port.py
  for k8files in $(ls ~/*.sh)
      do 
          sh xsync $k8files
      done
  log_info "  Start build kubernetes master and slave"
  sh xsync ~/functions.ksh
  echo "if [ -f ~/master-slave.sh ]; then "   >> ~/.bash_profile
  echo "    . ~/master-slave.sh"              >> ~/.bash_profile
  echo "fi"                                   >> ~/.bash_profile
  source  ~/.bash_profile
  sh xsync ~/.bash_profile
  inst_node master-slave.sh
  inst_node k8s_prepare.sh   
  inst_balance masterconfig.sh $MASTERIP
  inst_balance backupconfig.sh $BACKUPIP
  sh cfssl_inst.sh
  sh gencert.sh
  sh etcd_inst.sh  
  sh xsync ~/.bash_profile
  parall etcd.sh
  sh flanneld_inst.sh
  flanneld_network_init
  inst_node flanneld.sh
  inst_node docker.sh 
  sh kubernetes_inst.sh
  sh kubeconfig.sh
  sh kube-apiserver.sh
  ssh ${BACKUPNODE} "sh ~/kube-apiserver.sh"
  sh kube-controller-manager.sh
  ssh ${BACKUPNODE} "sh ~/kube-controller-manager.sh"
  sh kube-schedule.sh
  ssh ${BACKUPNODE} "sh ~/kube-schedule.sh"
  inst_node kube-proxy.sh
  inst_node kubelet.sh 
  kcheck
}

cluster()
{ 
  echo ${RUNDIR}
  cp -p ${RUNDIR}/{*.sh,*.py,*.ksh} ~
  sh xsync check_port.py
  for k8files in $(ls *.sh)
      do 
          sh xsync $k8files
      done
  log_info "  Start build kubernetes cluster"
  sh xsync ~/funcations.ksh
  echo "if [ -f ~/cluster.sh ]; then "   >> ~/.bash_profile
  echo "    . ~/cluster.sh"              >> ~/.bash_profile
  echo "fi"                                   >> ~/.bash_profile
  source  ~/.bash_profile
  inst_node master-slave.sh
  inst_node k8s_prepare.sh   
  inst_balance masterconfig.sh $MASTERIP
  inst_balance backupconfig.sh $BACKUPIP
  sh cfssl_inst.sh
  sh gencert.sh
  sh etcd_inst.sh  
  sh xsync ~/.bash_profile
  parall etcd.sh
  sh flanneld_inst.sh
  flanneld_network_init
  inst_node flanneld.sh
  inst_node docker.sh 
  sh kubernetes_inst.sh
  sh kubeconfig.sh
  sh kube-apiserver.sh
  ssh ${BACKUPNODE} "sh ~/kube-apiserver.sh"
  sh kube-controller-manager.sh
  ssh ${BACKUPNODE} "sh ~/kube-controller-manager.sh"
  sh kube-schedule.sh
  ssh ${BACKUPNODE} "sh ~/kube-schedule.sh"
  inst_node kube-proxy.sh
  inst_node kubelet.sh 
}

# INIT master node
inst_master()
{
	i=0 
	for i in `seq 0 ${#MASTER_IPS[@]}` ;
		do 
			if [ -z ${MASTER_IPS[$i]} ]; then	
				break
			else
				# log_info "copy $1 to server ${MASTER_IPS[$i]} "
				# scp -p ${PWD}/$1 ${MASTER_IPS[$i]}:~
				# log_info "Exectue $1 in server ${MASTER_IPS[$i]}  "
        check_ssh ${MASTER_IPS[$i]}
				ssh ${MASTER_IPS[$i]} "sh /root/$1"
			fi
		done
}


# install worknode
inst_node()
{
  . ~/master-slave.sh
	i=0 
	for i in `seq 0 ${#NODE_IPS[@]}` ;
		do 
			if [ -z ${NODE_IPS[$i]} ]; then	
				break
			else
      	# log_info "copy $1 to server ${NODE_IPS[$i]} "
        check_ssh ${NODE_IPS[$i]}
				# scp -p ${PWD}/$1 ${NODE_IPS[$i]}:~
				# log_info "Exectue $1 in server ${NODE_IPS[$i]}  "
				#ssh ${NODE_IPS[$i]} "whoami"
				ssh ${NODE_IPS[$i]} "sh /root/$1"
			fi
		done
}

# install ETCD SERVICE
inst_etcd()
{
	i=0 
	for i in `seq 0 ${#ETCD_NODE_NAMES_DOMAIN[@]}` ;
		do 
			if [ -z ${ETCD_NODE_NAMES_DOMAIN[$i]} ]; then	
				break
			else
				# log_info "copy $1 to server ${ETCD_NODE_NAMES_DOMAIN[$i]} "
				# scp -p ${PWD}/$1 ${ETCD_NODE_NAMES_DOMAIN[$i]}:~
				# scp -rp ${ETCD_SSL_DIR} ${ETCD_NODE_NAMES_DOMAIN[$i]}:${ETCD_SSL_DIR}
				# scp -rp ${SSL_DIR} ${ETCD_NODE_NAMES_DOMAIN[$i]}:${SSL_DIR}
				# log_info "Exectue $1 in server ${ETCD_NODE_NAMES_DOMAIN[$i]}  "
        sshcmd="$1"
        check_ssh ${ETCD_NODE_NAMES_DOMAIN[$i]}
				ssh ${ETCD_NODE_NAMES_DOMAIN[$i]} "sh $1 &"
			fi
		done
}

kcheck() {
  echo 
  kubectl get cs
  echo
  kubectl cluster-info 
  echo
  kubectl get nodes 
  echo
}

# install master and slave balance
inst_balance()
{ 
  scp -p $1 $2:/root/
  ssh $2 "sh /root/$1"
}

# flanneld_network
flanneld_network_init()
{
source ~/.bash_profile
export ETCDCTL_API=2
export certs="--ca-file=${SSL_DIR}/ca.pem --cert-file=${SSL_DIR}/flanneld.pem --key-file=${SSL_DIR}/flanneld-key.pem"
export endpoint="--endpoints=${ETCD_SERVERS}"
etcdctl $certs $endpoint member list && etcdctl $certs $endpoint cluster-health
if [ $? -eq 0 ]; then
  etcd is ready!
else
   log_error "check etcd status and try again"
   exit 8
fi
etcdctl $certs $endpoint get /atomic.io/network/config
if [ $? -eq 0 ]; then
	log_info "    /atomic.io/network/config alread exist"
else
	etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16","Backend": {"Type": "vxlan"}}'
fi
}

##########################################################
#                       MAIN                             #
##########################################################
PWD=$(pwd)
prog="$(basename ${0})"
RUNDIR="$( cd "$(dirname "${0}")" && pwd )"
if ! [ -d /var/kubernetes ] ; then
  mkdir /var/kubernetes/logs -p
fi
LOG_FILE_DIR="/var/kubernetes/logs"
RC=0
starttime=$(date +%s)
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
echo "log file: ${LogFile}"

if [ $# -gt 1 ]; then
  echo  $#
  usage
  exit 8
fi

case $1 in
      st)
        standalone
        ;;
      cl)
        cluster
        ;;
      ms)
        masterslave
        ;;
      *)
        usage
        ;;
esac

ende=$(date +%s)
diff=$((ende - starttime))
log_info  "  $(date)   Runtime      :   $diff" | tee -a $LogFile
log_info  "  Save log to ${LogFile}             "  | tee -a $LogFile
logrename  ${LogFile}