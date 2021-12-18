#!/bin/bash
pwd=$PWD
for i in 70 71 72 73; do scp etcd*.pem win$i:/etc/etcd/ssl/ ;done
for i in 70 71 72 73; do scp *.pem win$i:/etc/kubernetes/ssl/; done

#-----------------------
#查看证书有效期
for item in $(ls *.pem |grep -v key) ;do echo ======================$item===================;openssl x509 -in $item -text -noout| grep Not;done