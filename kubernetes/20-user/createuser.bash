#!/bin/bash
id=$1
APISERVER=10.10.10.100
export KUBE_APISERVER="https://${APISERVER}:6443"
SSL_DIR=/etc/kubernetes/ssl

cat > ${id}-csr.json <<EOF
{
  "CN": "system:node:${id}",
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
          "O": "system:nodes",
          "OU": "system"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server ${id}-csr.json | cfssljson -bare ${id}
cat > ${id}certificatesreqest.yaml <<EOF 
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${id}
spec:
  groups:
  - system:authenticated
  request: $(cat ${id}.csr | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
kubectl apply -f ${id}certificatesreqest.yaml
kubectl get csr
sleep 2

#approve csr for this account 
kubectl certificate approve ${id};  

cat >${id}rolebinding.yaml <<EOF  
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  name: cluster-amin-${id}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-amin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${id} 
EOF
kubectl apply -f ${id}rolebinding.yaml
kubectl config set-cluster kubernetes --certificate-authority=${SSL_DIR}/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=${id}.conf
kubectl config set-credentials admin --client-certificate=${id}.pem --client-key=${id}-key.pem --embed-certs=true --kubeconfig=${id}.conf
kubectl config set-context ${id} --cluster=kubernetes --user=${id} --kubeconfig=${id}.conf
kubectl config use-context ${id} --kubeconfig=${id}.conf

# openssl genrsa -out ${id}.key 2048;
# sleep 2s;
# openssl req -new -key ${id}.key -out ${id}.csr -subj "/CN=${id}/O=system";
# sleep 2s;
# cat > ${id}certificatesreqest.yaml <<EOF 
# apiVersion: certificates.k8s.io/v1
# kind: CertificateSigningRequest
# metadata:
  # name: ${id}
# spec:
  # groups:
  # - system:authenticated
  # request: $(cat ${id}.csr | base64 | tr -d "\n")
  # signerName: kubernetes.io/kube-apiserver-client
  # usages:
  # - client auth
# EOF

# kubectl apply -f ${id}certificatesreqest.yaml
# kubectl certificate approve ${id};

# cat >${id}rolebinding.yaml <<EOF  
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
  # annotations:
    # rbac.authorization.kubernetes.io/autoupdate: "true"
  # name: lih8hz-admin 
# roleRef:
  # apiGroup: rbac.authorization.k8s.io
  # kind: ClusterRole
  # name: cluster-amin 
# subjects:
# - apiGroup: rbac.authorization.k8s.io
  # kind: User
  # name: ${id} 
# EOF
# kubectl apply -f ${id}rolebinding.yaml
# kubectl get csr ${id} -o jsonpath='{.status.certificate}' | base64 -d >${id}.crt
# sleep 2s
