#!/bin/bash
for ip in NODE_IPS;
    do 
    mkdir /etc/etcd/{data,cfg,ssl} -p
    mkdir /etc/kubernetes/{cfg,ssl,logs,flanneld,manifests}  -p
    mkdir /etc/kubernetes/logs/{kubelet,kube-proxy,kube-scheduler,kube-apiserver,kube-controller-manager} -p
    