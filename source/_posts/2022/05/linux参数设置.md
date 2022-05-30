---
title: linux参数设置
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-27 09:09:56
tags:
---

```
#关闭防火墙
systemctl disable --now firewalld
#关闭selinux
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
#关闭交换区
sed -ri 's/.*swap.*/#&/' /etc/fstab
swapoff -a && sysctl -w vm.swappiness=0

cat /etc/fstab
# /dev/mapper/centos-swap swap                    swap    defaults        0 0
#关闭NetworkManager 并启用 network
systemctl disable --now NetworkManager
systemctl start network && systemctl enable network
进行时间同步 (lb除外)
# 服务端

yum install chrony -y
cat > /etc/chrony.conf << EOF 
pool ntp.aliyun.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
allow 10.0.0.0/24
local stratum 10
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF

systemctl restart chronyd
systemctl enable chronyd

# 客户端

yum install chrony -y
vim /etc/chrony.conf
cat /etc/chrony.conf | grep -v  "^#" | grep -v "^$"
pool 10.0.0.81 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony

systemctl restart chronyd ; systemctl enable chronyd

# 客户端安装一条命令
yum install chrony -y ; sed -i "s#2.centos.pool.ntp.org#10.0.0.81#g" /etc/chrony.conf ; systemctl restart chronyd ; systemctl enable chronyd


#使用客户端进行验证
chronyc sources -v
1.12.配置ulimit
ulimit -SHn 65535
cat >> /etc/security/limits.conf <<EOF
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* seft memlock unlimited
* hard memlock unlimitedd
EOF
修改内核参数 (lb除外)
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
fs.may_detach_mounts = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720


net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1

EOF

sysctl --system


```
