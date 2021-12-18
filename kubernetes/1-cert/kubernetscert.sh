#!/bin/bash
#配置文件，默认签 10 年
cat >client-csr.json <<EOF
{
  "CN": "client",
  "hosts": [
  ],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
#this is generate client.pem client-key.pem which is using for kube-apiserver for access etcd 
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json |cfssljson -bare client
#-----------------------
#颁发给管理员管理集群
cat > admin-csr.json <<EOF
{
  "CN": "system:node:admin",
  "hosts": [],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:nodes",  # can only using 'system:nodes'
          "OU": "system"
    }
  ]
}
EOF
###this is for admin user using
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server admin-csr.json | cfssljson -bare admin
##--apiserver
cat > apiserver-csr.json <<EOF
{
  "CN": "system:masters:kube-apiserver",
  "hosts": [
      "127.0.0.1",
      "win70.inno.com",
      "win71.inno.com",
      "win72.inno.com",
      "win73.inno.com",
      "win74.inno.com",
      "win75.inno.com",
      "win76.inno.com",
      "win200.inno.com",
	  "win100.inno.com",
      "10.10.10.100",
      "10.244.0.1",
      "10.96.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare apiserver

cat > kubectl-csr.json <<EOF
{
  "CN": "system:masters:kubectl",
  "hosts": [
      "127.0.0.1",
      "win70.inno.com",
      "win71.inno.com",
      "win72.inno.com",
      "win73.inno.com",
      "win74.inno.com",
      "win75.inno.com",
      "win76.inno.com",
      "win200.inno.com",
	  "win100.inno.com",
      "10.10.10.100"
],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubectl-csr.json | cfssljson -bare kubectl
cat > kubecontroller-csr.json <<EOF
{
  "CN": "system:masters:kube-controller-manager",
  "hosts": [
      "127.0.0.1",
      "win70.inno.com",
      "win71.inno.com",
      "win72.inno.com",
      "win73.inno.com",
      "win74.inno.com",
      "win75.inno.com",
      "win76.inno.com",
      "win200.inno.com",
	  "win100.inno.com",
      "10.10.10.100",
      "10.244.0.1",
      "10.96.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubecontroller-csr.json | cfssljson -bare kube-controller-manager

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:masters:kube-scheduler",
  "hosts": [
      "127.0.0.1",
      "win70.inno.com",
      "win71.inno.com",
      "win72.inno.com",
      "win73.inno.com",
      "win74.inno.com",
      "win75.inno.com",
      "win76.inno.com",
      "win200.inno.com",
	  "win100.inno.com",
      "10.10.10.100",
      "10.244.0.1",
      "10.96.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-scheduler-csr.json | cfssljson -bare kube-scheduler

cat > kubelet-csr.json <<EOF
{
  "CN": "system:masters:kubelet",
  "hosts": [
      "127.0.0.1",
      "win70.inno.com",
      "win71.inno.com",
      "win72.inno.com",
      "win73.inno.com",
      "win74.inno.com",
      "win75.inno.com",
      "win76.inno.com",
      "win200.inno.com",
	  "win100.inno.com",
      "10.10.10.100"
],
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json | cfssljson -bare kubelet


cat > kubeproxy-csr.json <<EOF
{
  "CN": "system:masters:kubeproxy",
  "key": {
      "algo": "ecdsa",
      "size": 256
  },
  "names": [
      {
          "C": "CN",
          "ST": "Henan",
          "L": "nanyang",
          "O": "system:masters",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client kubelet-csr.json | cfssljson -bare kubeproxy-client