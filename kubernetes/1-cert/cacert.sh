#!/bin/bash
cat >ca-config.json <<EOF
{
  "signing": {
      "default": {
      "expiry": "87600h"
      },
     "profiles": {
         "server": {
             "expiry": "87600h",
             "usages": [
                 "signing",
                 "key encipherment",
                 "server auth",
                 "client auth"
                 ]
	     },
         "client": {
	     "expiry": "87600h",
             "usages": [
                 "signing",
                 "key encipherment",
                 "server auth",
                 "client auth"
            ]
        },
         "peer": {
	    "expiry": "87600h",
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
      }
    }
  }
}
EOF
cat >ca-csr.json <<EOF
{
  "CN": "system:masters:etcd",  
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
  ],
  "ca": {
	  "expiry": "87600h"
  }
}
EOF
# generate ca.pem and ca-key.pem
cfssl gencert -initca ca-csr.json | cfssljson -bare ca - 