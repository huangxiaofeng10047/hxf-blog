---
title: ubuntu安装指定版本kubernets
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-03 16:49:14
tags:
---

安装介绍：

以下是手动安装k8s workernode。

```shell
#安装nfs
sudo apt install nfs-kernel-server
#安装containerd
apt-get install  containerd.io
vi /etc/apt/sources.list
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -i "s#k8s.gcr.io#registry.aliyuncs.com/k8sxio#g"  /etc/containerd/config.toml
sed -i '/containerd.runtimes.runc.options/a\ \ \ \ \ \ \ \ \ \ \ \ SystemdCgroup = true' /etc/containerd/config.toml
sed -i "s#https://registry-1.docker.io#${REGISTRY_MIRROR}#g"  /etc/containerd/config.toml
#添加如下语句
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
#保存退出
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add 
#添加key
#安装kubeadm kubelete
apt-get update && apt-get install -y apt-transport-https curl
apt-get install -y kubelet kubeadm kubectl --allow-unauthenticated
# 关闭 防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭 SeLinux
setenforce 0
# 关闭 swap
swapoff -a
modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
```

tip

```
#卸载版本
apt-get purge / apt-get --purge remove
```

