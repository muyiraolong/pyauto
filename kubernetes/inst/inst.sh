#!/bin/bash
##########################################################
# init running  enviroment 
##########################################################
PWD=$(pwd)
source  ${PWD}/master-slave.sh
source  ~/.bash_profile

inst_master()
{
	i=0 
	for i in `seq 0 ${#MASTER_IPS[@]}` ;
		do 
			if [ -z ${MASTER_IPS[$i]} ]; then	
				break
			else
				echo "copy $1 to server ${MASTER_IPS[$i]} "
				scp -p ${PWD}/$1 ${MASTER_IPS[$i]}:/root/
				echo "Exectue $1 in server ${MASTER_IPS[$i]}  "
				# ssh ${MASTER_IPS[$i]} "whoami"
				ssh ${MASTER_IPS[$i]} "sh /root/$1"
			fi
		done
}

inst_node()
{
	i=0 
	for i in `seq 0 ${#NODE_IPS[@]}` ;
		do 
			if [ -z ${NODE_IPS[$i]} ]; then	
				break
			else
				echo "copy $1 to server ${NODE_IPS[$i]} "
				scp -p ${PWD}/$1 ${NODE_IPS[$i]}:/root/
				echo "Exectue $1 in server ${NODE_IPS[$i]}  "
				#ssh ${NODE_IPS[$i]} "whoami"
				ssh ${NODE_IPS[$i]} "sh /root/$1"
			fi
		done
}

inst_etcd()
{
	i=0 
	for i in `seq 0 ${#ETCD_NODE_NAMES_DOMAIN[@]}` ;
		do 
			if [ -z ${ETCD_NODE_NAMES_DOMAIN[$i]} ]; then	
				break
			else
				echo "copy $1 to server ${ETCD_NODE_NAMES_DOMAIN[$i]} "
				scp -p ${PWD}/$1 ${ETCD_NODE_NAMES_DOMAIN[$i]}:/root/
				echo "Exectue $1 in server ${ETCD_NODE_NAMES_DOMAIN[$i]}  "
				#ssh ${ETCD_NODE_NAMES_DOMAIN[$i]} "whoami"
				ssh ${ETCD_NODE_NAMES_DOMAIN[$i]} "sh /root/$1"
			fi
		done
}

inst_balance()
{ 
scp -p $1 $2:/root/
ssh $2 "sh /root/$1"
}

##########################################################
# flanneld_network 
##########################################################
flanneld_network()
{
export ETCDCTL_API=2
export certs="--ca-file=${SSL_DIR}/ca.pem --cert-file=${SSL_DIR}/flanneld.pem --key-file=${SSL_DIR}/flanneld-key.pem"
export endpoint="--endpoints=${ETCD_SERVERS}"

etcdctl $certs $endpoint get /atomic.io/network/config
if [ $? -eq 0 ]; then
	echo "/atomic.io/network/config alread exist"
else
	etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16","Backend": {"Type": "vxlan"}}'
fi
}


##########################################################
#                       MAIN                             #
##########################################################
inst_node master-slave.sh
inst_node package-pre.sh
inst_balance masterconfig.sh $MASTERIP
inst_balance backupconfig.sh $BACKUPIP
sh k8scert.sh
inst_etcd etcd.sh
flanneld_network
inst_node flanneld.sh
inst_node docker.sh
inst_node kubeconfig.sh
inst_master kube-apiserver.sh
inst_master kube-controller-manager.sh
inst_master kube-schedule.sh
inst_node kube-proxy.sh
inst_node kubelet.sh