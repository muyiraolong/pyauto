#!/bin/bash
##########################################################
# init running  enviroment 
##########################################################
PWD=$(pwd)
source  ${PWD}/master-slave.sh
source  ~/.bash_profile

add-worknode()
{ 
scp -p $1 $2:/root/
ssh $2 "sh /root/$1"
}

##########################################################
#                       MAIN                             #
##########################################################
add-worknode master-slave.sh
add-worknode package-pre.sh 
#sh k8scert.sh
add-worknode flanneld.sh
add-worknode docker.sh
add-worknode kubeconfig.sh
add-worknode kube-proxy.sh
add-worknode kubelet.sh