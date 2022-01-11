#!/bin/bash
yum -y install haproxy keepalived
cat <<EOF >/etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_DEVEL
script_user root
   enable_script_security
}
vrrp_script chk_apiserver {
   script "/etc/keepalived/check_apiserver.sh"
   interval 5
   weight -5
   fall 2 
rise 1
}
vrrp_instance VI_1 {
   state MASTER
   interface ens224
   mcast_src_ip ${MASTERIP}
   virtual_router_id 51
   priority 100
   advert_int 2
   authentication {
       auth_type PASS
       auth_pass K8SHA_KA_AUTH
   }
   virtual_ipaddress {
       ${APISERVER}
   }
   track_script {
      chk_apiserver
   }
}
EOF

cat <<EOF >/etc/keepalived/check_apiserver.sh
#!/bin/bash
err=0
for k in $(seq 1 3)
do
   check_code=$(pgrep haproxy)
   if [[ $check_code == "" ]]; then
       err=$(expr $err + 1)
       sleep 1
       continue
   else
       err=0
       break
   fi
done

if [[ $err != "0" ]]; then
   echo "systemctl stop keepalived"
   /usr/bin/systemctl stop keepalived
   exit 1
else
   exit 0
fi
EOF

#haproxy.cfg配置文件
cat <<EOF >/etc/haproxy/haproxy.cfg
global
 maxconn 2000
 ulimit-n 16384
 log 127.0.0.1 local0 err
 stats timeout 30s

defaults
 log global
 mode http
 option httplog
 timeout connect 5000
 timeout client 50000
 timeout server 50000
 timeout http-request 15s
 timeout http-keep-alive 15s

frontend monitor-in
 bind *:33305
 mode http
 option httplog
 monitor-uri /monitor

frontend k8s-master
#bind 0.0.0.0:16443
#bind 127.0.0.1:16443
 bind *:6443
 mode tcp
 timeout client 1h
 log global
 option tcplog
 default_backend k8s-master
 tcp-request inspect-delay 5s
 acl is_websocket hdr(Upgrade) -i WebSocket
 acl is_websocket hdr_beg(Host) -i ws


backend k8s-master
 mode tcp
 option tcplog
 option tcp-check
 balance roundrobin
 default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
 server  ${MASTERNODE}  ${MASTERIP}:6443 check
 server  ${BACKUPNODE}  ${BACKUPIP}:6443 check
EOF
chmod 755 /etc/keepalived/check_haproxy.sh
systemctl start keepalived && systemctl enable keepalived
systemctl start haproxy && systemctl enable haproxy