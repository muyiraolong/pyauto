#!/bin/bash
APISERVER=10.10.10.100
SSL_DIR=/etc/kubernetes/ssl
kadmin=`kubectl get secrets -n kube-system|grep dashboard-admin|awk 'NR=1{print$1}'`
echo $kadmin
token=`kubectl describe -n kube-system secrets ${kadmin}|grep -i token:`
echo $token
DASH_TOKEN=`echo $token|awk 'NR=1{print$2}'`
echo "find token is"
echo $DASH_TOKEN
export KUBE_APISERVER="https://${APISERVER}:6443"
kubectl config set-cluster kubernetes --server=${KUBE_APISERVER} --kubeconfig=dashboard-admin.conf
kubectl config set-credentials admin --token=${DASH_TOKEN} --kubeconfig=dashboard-admin.conf
kubectl config set-context admin --cluster=kubernetes --user=admin --kubeconfig=dashboard-admin.conf
kubectl config use-context admin --kubeconfig=dashboard-admin.conf