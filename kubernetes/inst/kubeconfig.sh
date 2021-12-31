#!/bin/bash

# APISERVER=10.10.10.72
# SSL_DIR=/etc/kubernetes/ssl

# export KUBE_APISERVER="https://${APISERVER}:6443"

######################################create for admin ###################################################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=${CFG_DIR}/admin.kubeconfig
kubectl config set-credentials admin --client-certificate=${SSL_DIR}/admin.pem --client-key=${SSL_DIR}/admin-key.pem --embed-certs=true\
 --kubeconfig=${CFG_DIR}/admin.kubeconfig
kubectl config set-context admin --cluster=kubernetes --user=admin --kubeconfig=${CFG_DIR}/admin.kubeconfig
kubectl config use-context admin --kubeconfig=${CFG_DIR}/admin.kubeconfig
######################################create for admin end ###############################################################################
#above may not need


#floowing is correct 
########################################################creaet kubectl.kubeconfig#########################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=${CFG_DIR}/kubectl.kubeconfig
kubectl config set-credentials clusteradmin --client-certificate=${SSL_DIR}/kubectl.pem --client-key=${SSL_DIR}/kubectl-key.pem  --embed-certs=true --kubeconfig=${CFG_DIR}/kubectl.kubeconfig
kubectl config set-context clusteradmin --cluster=kubernetes --user=clusteradmin --kubeconfig=${CFG_DIR}/kubectl.kubeconfig
kubectl config use-context clusteradmin --kubeconfig=${CFG_DIR}/kubectl.kubeconfig
mkdir -p /root/.kube
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=/root/.kube/config
kubectl config set-credentials clusteradmin --client-certificate=${SSL_DIR}/kubectl.pem --client-key=${SSL_DIR}/kubectl-key.pem  --embed-certs=true --kubeconfig=/root/.kube/config
kubectl config set-context clusteradmin --cluster=kubernetes --user=clusteradmin --kubeconfig=/root/.kube/config
kubectl config use-context clusteradmin --kubeconfig=/root/.kube/config
#kubectl config use-context default --kubeconfig=kubernetes/kubectl.kubeconfig
#enable kubectl connect to apiserver
######################################################## creaet kubectl end####################################################

####################################################create controller-manager.kubeconfig##################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig
kubectl config set-credentials kube-controller-manager --client-certificate=${SSL_DIR}/kube-controller-manager.pem --client-key=${SSL_DIR}/kube-controller-manager-key.pem --embed-certs=true --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-controller-manager --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig
kubectl config use-context default --kubeconfig=${CFG_DIR}/kube-controller-manager.kubeconfig
#####################################################create controller-manager.kubeconfig end##############################################

####################################################create kube-scheduler.kubeconfig#######################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig
kubectl config set-credentials kube-scheduler --client-certificate=${SSL_DIR}/kube-scheduler.pem \
--client-key=${SSL_DIR}/kube-scheduler-key.pem --embed-certs=true --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-scheduler --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig
kubectl config use-context default --kubeconfig=${CFG_DIR}/kube-scheduler.kubeconfig
#####################################################create kube-scheduler.kubeconfig  end##################################################

#####################################################create kubelet.kubeconfig##############################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=${CFG_DIR}/kubelet.kubeconfig
kubectl config set-credentials kubernetes --client-certificate=${SSL_DIR}/kubelet.pem --client-key=${SSL_DIR}/kubelet-key.pem \
--embed-certs=true --kubeconfig=${CFG_DIR}/kubelet.kubeconfig
kubectl config set-context kubernetes --cluster=kubernetes --user=kubernetes --kubeconfig=${CFG_DIR}/kubelet.kubeconfig
kubectl config use-context kubernetes --kubeconfig=${CFG_DIR}/kubelet.kubeconfig
#####################################################create kubelet.kubeconfig end #########################################################

#####################################################create kube-proxy kubeconfig###########################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy --client-certificate=${SSL_DIR}/kube-proxy.pem --client-key=${SSL_DIR}/kube-proxy-key.pem \
--embed-certs=true --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=${CFG_DIR}/kube-proxy.kubeconfig
#################################################### Create kube-proxy kubeconfig end ######################################################
#####################################################create kube-proxy kubeconfig###########################################################
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} \
--kubeconfig=${CFG_DIR}/flanneld.kubeconfig
kubectl config set-credentials flanneld --client-certificate=${SSL_DIR}/flanneld.pem --client-key=${SSL_DIR}/flanneld-key.pem \
--embed-certs=true --kubeconfig=${CFG_DIR}/flanneld.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=flanneld --kubeconfig=${CFG_DIR}/flanneld.kubeconfig
kubectl config use-context default --kubeconfig=${CFG_DIR}/flanneld.kubeconfig
#################################################### Create kube-proxy kubeconfig end ######################################################
#following need change
#for i in 70 71;do scp -p ${CFG_DIR}/*kubeconfig win$i:${CFG_DIR}/ ;done
#for i in 70 71 72;do scp -p ${CFG_DIR}/{kubelet.kubeconfig,kube-proxy.kubeconfig} win$i:${CFG_DIR}/;done
#for i in 70 71 72;do scp -p /root/.kube/config win$i:/root/.kube/config;done
#for i in 70 71 72;do ssh win$i"chmod g-r ~/.kube/config;chmod o-r ~/.kube/config"; done