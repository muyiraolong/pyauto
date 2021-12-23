export ETCDCTL_API=2
certs="--ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/flanneld.pem --key-file=/etc/kubernetes/ssl/flanneld-key.pem"
endpoint="--endpoints=https://win70.inno.com:2379,https://win71.inno.com:2379,https://win72.inno.com:2379"
#etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16", "SubnetLen": 16,"Backend": {"Type": "vxlan"}}'
etcdctl $certs $endpoint mk /atomic.io/network/config '{"Network": "10.244.0.0/16","Backend": {"Type": "vxlan"}}'
etcdctl $certs $endpoint get /atomic.io/network/config