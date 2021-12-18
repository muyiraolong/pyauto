#!/bin/bash

APISERVER=10.10.10.100
SSL_DIR=/etc/kubernetes/ssl

export KUBE_APISERVER="https://${APISERVER}:6443"

######################################create for admin ###################################################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=kubernetes/admin.kubeconfig
kubectl config set-credentials admin --client-certificate=${SSL_DIR}/admin.pem --client-key=${SSL_DIR}/admin-key.pem --embed-certs=true\
 --kubeconfig=kubernetes/admin.kubeconfig
kubectl config set-context admin --cluster=kubernetes --user=admin --kubeconfig=kubernetes/admin.kubeconfig
kubectl config use-context admin --kubeconfig=kubernetes/admin.kubeconfig
######################################create for admin end ###############################################################################
#above may not need


#floowing is correct 
########################################################creaet kubectl.kubeconfig#########################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=kubernetes/kubectl.kubeconfig
kubectl config set-credentials clusteradmin --client-certificate=${SSL_DIR}/kubectl.pem --client-key=${SSL_DIR}/kubectl-key.pem \
 --embed-certs=true --kubeconfig=kubernetes/kubectl.kubeconfig
kubectl config set-context clusteradmin --cluster=kubernetes --user=clusteradmin --kubeconfig=kubernetes/kubectl.kubeconfig
kubectl config use-context clusteradmin --kubeconfig=kubernetes/kubectl.kubeconfig
#kubectl config use-context default --kubeconfig=kubernetes/kubectl.kubeconfig
#enable kubectl connect to apiserver

######################################################## creaet kubectl.kubeconfig end####################################################

####################################################create controller-manager.kubeconfig##################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=kubernetes/kube-controller-manager.kubeconfig
kubectl config set-credentials kube-controller-manager \
 --client-certificate=${SSL_DIR}/kube-controller-manager.pem --client-key=${SSL_DIR}/kube-controller-manager-key.pem \
 --embed-certs=true --kubeconfig=kubernetes/kube-controller-manager.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-controller-manager \
 --kubeconfig=kubernetes/kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=kubernetes/kube-controller-manager.kubeconfig
#####################################################create controller-manager.kubeconfig end##############################################

####################################################create kube-scheduler.kubeconfig#######################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=kubernetes/kube-scheduler.kubeconfig
kubectl config set-credentials kube-scheduler --client-certificate=${SSL_DIR}/kube-scheduler.pem \
--client-key=${SSL_DIR}/kube-scheduler-key.pem --embed-certs=true --kubeconfig=kubernetes/kube-scheduler.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-scheduler --kubeconfig=kubernetes/kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=kubernetes/kube-scheduler.kubeconfig
#####################################################create kube-scheduler.kubeconfig  end##################################################

#####################################################create kubelet.kubeconfig##############################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=kubernetes/kubelet.kubeconfig 
kubectl config set-credentials kubernetes --client-certificate=${SSL_DIR}/client.pem --client-key=${SSL_DIR}/client-key.pem \
--embed-certs=true --kubeconfig=kubernetes/kubelet.kubeconfig
kubectl config set-context kubernetes --cluster=kubernetes --user=kubernetes --kubeconfig=kubernetes/kubelet.kubeconfig
kubectl config use-context kubernetes --kubeconfig=kubernetes/kubelet.kubeconfig
#####################################################create kubelet.kubeconfig end #########################################################

#####################################################create kube-proxy kubeconfig###########################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=kubernetes/kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy --client-certificate=${SSL_DIR}/kubeproxy-client.pem \
--client-key=${SSL_DIR}/kubeproxy-client-key.pem \
--embed-certs=true --kubeconfig=kubernetes/kube-proxy.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=kubernetes/kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kubernetes/kube-proxy.kubeconfig
#################################################### Create kube-proxy kubeconfig end ######################################################


#following need change
for i in 70 71;do scp -p /mnt/hgfs/kubernetes/package/k8s/kubeconfig/kubernetes/*kubeconfig win$i:/etc/kubernetes/cfg/ ;done
for i in 70 71 72 73;do scp -p /mnt/hgfs/kubernetes/package/k8s/kubeconfig/kubernetes/{kubelet.kubeconfig,kube-proxy.kubeconfig} win$i:/etc/kubernetes/cfg/;done
for i in 70 71 72;do scp -p /mnt/hgfs/kubernetes/1_bink8sinst/kubeconfig/kubernetes/kubectl.kubeconfig win$i:/root/.kube/config;done
for i in 70 71 72;do ssh win$i"chmod g-r ~/.kube/config;chmod o-r ~/.kube/config"; done
for i in 70 71;do scp -p /mnt/hgfs/kubernetes/package/k8s/kubeconfig/{kube-apiserver.service,kube-controller-manager.service,kube-scheduler.service} win$i:$tt ;done
for i in 70 71 72 73;do scp -p /mnt/hgfs/kubernetes/package/k8s/kubeconfig/{kube-proxy.service,kubelet.service} win$i:$tt ;done
for i in 70 71 72 73;do scp -p /mnt/hgfs/kubernetes/package/k8s/kubeconfig/kube-proxy.service win$i:$tt ;done