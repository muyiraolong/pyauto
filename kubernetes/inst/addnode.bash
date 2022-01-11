#!/bin/bash
###################################################################
#Script Name	:   add k8s worknode
#Description	:
#Args        	:
#Author       	: innod
#Email         	: motingxia@163.com
###################################################################


###################################################################
# init running  enviroment 
###################################################################
PWD=$(pwd)
source  ${PWD}/master-slave.sh
source  ~/.bash_profile

addknode()
{ 
scp -p $1 $2:/root/
ssh $2 "sh /root/$1"
}

###################################################################
#                       MAIN                                      #
###################################################################
addnode master-slave.sh
addnode package-pre.sh
#sh k8scert.sh
addnode flanneld.sh
addnode docker.sh
addnode kubeconfig.sh
addnode kube-proxy.sh
addnode kubelet.sh