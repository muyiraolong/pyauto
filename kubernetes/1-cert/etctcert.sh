#!/bin/bash
cat >server-csr.json <<EOF
{
    "CN": "etcdpeer",
    "hosts": [
        "127.0.0.1",
	    "10.10.10.100",
		"win70",
        "win71",
        "win72",
        "win73",
        "win74",
        "win75",
        "win76",
		"win100",
		"win200",
		"innodb-inno-com",
        "win70.inno.com",
        "win71.inno.com",
        "win72.inno.com",
        "win73.inno.com",
        "win74.inno.com",
        "win75.inno.com",
        "win76.inno.com",
		"win100.inno.com",
		"win200.inno.com"],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "CN",
            "L": "Henan",
            "ST": "nanyang",
            "O": "system:masters",
            "OU": "System"
        }
    ]
}
EOF
#generate key for etcd server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer server-csr.json |cfssljson -bare server