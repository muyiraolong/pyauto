# rpm -e podman-1.0.0-2.git921f98f.module+el8+2785+ff8a053f.x86_64
# rpm -e buildah-1.5-3.gite94b4f9.module+el8+2769+577ad176.x86_64
# rpm -e fuse-overlayfs
# rpm -e slirp4netns
# rpm -e pcp-testsuite-4.3.0-3.el8.x86_64
# rpm -e pcp-pmda-docker-4.3.0-3.el8.x86_64
# rpm -ivh /mnt/hgfs/0_package/Docker/package/first/fuse-overlayfs-0.7.8-1.module_el8.3.0+479+69e2ae26.x86_64.rpm
# rpm -ivh /mnt/hgfs/0_package/Docker/package/first/slirp4netns-0.4.2-3.git21fdece.module_el8.3.0+479+69e2ae26.x86_64.rpm
# rpm -Uvh /mnt/hgfs/kubernetes/0_package/Docker/package/second/*
# rpm -Uvh /mnt/hgfs/kubernetes/0_package/Docker/package/libseccomp-devel/libseccomp-2.5.1-1.el8.x86_64.rpm
# rpm -ivh /mnt/hgfs/kubernetes/D0_package/Docker/package/libseccomp-devel/libseccomp-devel-2.5.1-1.el8.x86_64.rpm

# systemctl start docker && systemctl enable docker && 
systemctl stop docker

cat <<EOF >/etc/docker/daemon.json
{
    "registry-mirrors": ["https://registry.docker-cn.com"],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "insecure-registries": ["10.10.10.72:5000"],
    "log-driver": "json-file",
    "log-opts": {"max-size": "100m"}
}
EOF

cat <<EOF >/usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket containerd.service

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
EnvironmentFile=/etc/kubernetes/flanneld/docker_opts.env
ExecStart=/usr/bin/dockerd \$DOCKER_OPTS -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload;systemctl start docker
docker info