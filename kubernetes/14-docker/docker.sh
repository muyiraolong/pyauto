rpm -e podman-1.0.0-2.git921f98f.module+el8+2785+ff8a053f.x86_64
rpm -e buildah-1.5-3.gite94b4f9.module+el8+2769+577ad176.x86_64
rpm -e fuse-overlayfs
rpm -e slirp4netns
rpm -e pcp-testsuite-4.3.0-3.el8.x86_64
rpm -e pcp-pmda-docker-4.3.0-3.el8.x86_64
rpm -ivh /mnt/hgfs/0_package/Docker/package/first/fuse-overlayfs-0.7.8-1.module_el8.3.0+479+69e2ae26.x86_64.rpm
rpm -ivh /mnt/hgfs/0_package/Docker/package/first/slirp4netns-0.4.2-3.git21fdece.module_el8.3.0+479+69e2ae26.x86_64.rpm
rpm -Uvh /mnt/hgfs/kubernetes/0_package/Docker/package/second/*
rpm -Uvh /mnt/hgfs/kubernetes/0_package/Docker/package/libseccomp-devel/libseccomp-2.5.1-1.el8.x86_64.rpm
rpm -ivh /mnt/hgfs/kubernetes/D0_package/Docker/package/libseccomp-devel/libseccomp-devel-2.5.1-1.el8.x86_64.rpm

# systemctl start docker && systemctl enable docker

 cat > /etc/docker/daemon.json<<EOF
{
    "registry-mirrors":["https://registry.docker-cn.com"],
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl daemon reload;systemctl restart docker
docker info