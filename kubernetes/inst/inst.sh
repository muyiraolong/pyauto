#!/bin/bash




##########################################################
# init running  enviroment 
##########################################################
PWD=$(pwd)
source  ${PWD}/master-slave.sh
source  ~/.bash_profile

remote_command()
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
				ssh ${NODE_IPS[$i]} "whoami"
				# ssh $i "sh /root/$1"
			fi
		done
}
##########################################################
# etcd enviroment 
##########################################################
flanneld_network()
{
export ETCDCTL_API=2
certs="--ca-file=${SSL_DIR}/ca.pem --cert-file=${SSL_DIR}/flanneld.pem --key-file=${SSL_DIR}/flanneld-key.pem"
endpoint="--endpoints=${ETCD_SERVERS}"

etcdctl $certs $endpoint get /atomic.io/network/config
if [ $? -eq 0 ]; then
   echo "/atomic.io/network/config alread exist"
fi
#etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16","Backend": {"Type": "vxlan"}}'
}


remote_command etcd.sh
# sh k8scert.sh
flanneld_network
remote_command flanneld.sh
remote_command docker.sh
remote_command kubeconfig.sh
remote_command kube-apiserver.sh
remote_command kube-controller-manager.sh
remote_command kube-schedule.sh
remote_command kube-proxy.sh
remote_command kubelet.sh