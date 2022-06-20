---
title: >-
  Kubernetes安装rook-ceph集群时报MountVolume.SetUp failed for volume
  “rook-ceph-crash-collector-keyring” : secret
  “rook-ceph-crash-collector-keyring” not found
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-08 16:00:59
tags:
---

## 简介

在K8S集群中安装rook-ceph时报MountVolume.SetUp failed for volume “rook-ceph-crash-collector-keyring” : secret “rook-ceph-crash-collector-keyring” not found的错误，原因是之前使用国外的源，造成被墙了镜像一直拉不下来，后来换成国内源安装一直报错，无法安装。

## *2.*处理方法

### *2.1.*删除yaml的创建

```
kubectl delete -f cluster.yaml
kubectl delete -f operator.yaml
kubectl delete -f common.yaml
kubectl delete -f crds.yaml
```

### *2.2.*确认目录下有文件

```
ll /var/lib/rook/ /var/lib/kubelet/plugins/ /var/lib/kubelet/plugins_registry/
```

### *2.3.*删除之前失败的创建

```
rm -rf /var/lib/rook/* /var/lib/kubelet/plugins/* /var/lib/kubelet/plugins_registry/*
dd if=/dev/zero of=/dev/sda bs=512K count=1

rm -rf /dev/mapper/ceph--d4b7dc7a--8b2d--459f--8e21--4f5b811fd9c3-osd--block--f0aab02d--5edd--425a--9216--8d0f656c14b0



```

### *2.4.*重新创建集群

```
kubectl create -f crds.yamlkubectl create -f common.yamlkubectl create -f operator.yamlkubectl create -f cluster.yaml
```

````
官方步骤文档：[https://rook.io/docs/rook/v1.8/ceph-teardown.html](https://rook.io/docs/rook/v1.8/ceph-teardown.html)

请注意需要清理的以下资源：

-   rook-ceph namespace: The Rook operator and cluster created by operator.yaml and cluster.yaml (the cluster CRD)
-   `/var/lib/rook`: Path on each host in the cluster where configuration is cached by the ceph mons and osds

## Delete the Block and File artifacts

```
# 如下这些文件是官方文档中演示使用到的，若是没有操作过则可以跳过这一步
kubectl delete -f ../wordpress.yaml
kubectl delete -f ../mysql.yaml
kubectl delete -n rook-ceph cephblockpool replicapool
kubectl delete storageclass rook-ceph-block
kubectl delete -f csi/cephfs/kube-registry.yaml
kubectl delete storageclass csi-cephfs
```

## Delete the CephCluster CRD

```
kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'

kubectl -n rook-ceph delete cephcluster rook-ceph
kubectl -n rook-ceph get cephcluster
```

-   删除所有节点上的目录`/var/lib/rook`（或dataDirHostPath指定的路径）
-   擦除此群集中运行OSD的所有节点上驱动器上的数据

```
kubectl delete -f operator.yaml
kubectl delete -f common.yaml
kubectl delete -f crds.yaml
```

## Delete the data on hosts

连接到每台计算机并删除`/var/lib/rook`或dataDirHostPath指定的路径。

擦除磁盘数据

```
#!/usr/bin/env bash
DISK="/dev/sdb" # 根据实际情况修改(裸磁盘)

# Zap the disk to a fresh, usable state (zap-all is important, b/c MBR has to be clean)

# You will have to run this step for all disks.
sgdisk --zap-all $DISK

# Clean hdds with dd
dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync

# Clean disks such as ssd with blkdiscard instead of dd
blkdiscard $DISK

# These steps only have to be run once on each node
# If rook sets up osds using ceph-volume, teardown leaves some devices mapped that lock the disks.
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %

# ceph-volume setup can leave ceph-<UUID> directories in /dev and /dev/mapper (unnecessary clutter)
rm -rf /dev/ceph-*
rm -rf /dev/mapper/ceph--*

# Inform the OS of partition table changes
partprobe $DISK
```
````

另外一种

```
#卸载ceph
#k8s资源清理
cd rook/cluster/examples/kubernetes/ceph
kubectl delete -f toolbox.yaml
kubectl delete -f operator.yaml 
kubectl delete -f cluster.yaml 
kubectl delete -f crds.yaml
kubectl delete -f common.yaml

kubectl -n rook-ceph get job|tail -n +2|awk '{print $1}'|xargs kubectl -n rook-ceph delete job --force --grace-period=0
kubectl -n rook-ceph get deploy|tail -n +2|awk '{print $1}'|xargs kubectl -n rook-ceph delete deployments.apps --force --grace-period=0
kubectl -n rook-ceph get svc|tail -n +2|awk '{print $1}'|xargs kubectl -n rook-ceph delete svc --force --grace-period=0
kubectl -n rook-ceph get sa|tail -n +2|awk '{print $1}'|grep rook|xargs kubectl -n rook-ceph delete sa --force --grace-period=0

kubectl proxy &
NAMESPACE=rook-ceph
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
ps -ef |grep "kubectl proxy"|awk '{print $2}'|xargs kill -9

#各个节点硬盘和配置文件清理
yum -y install gdisk
rpm -qa|grep -E 'ceph|librbd|librados'|xargs yum -y remove
vgs|grep ceph|awk '{print $1}'|xargs -n 1 vgremove --yes
for i in {b..d}; do pvremove /dev/sd$i; done
for i in {b..d}; do sgdisk --zap-all sd$i; done
rm -rf /var/lib/rook/

```

