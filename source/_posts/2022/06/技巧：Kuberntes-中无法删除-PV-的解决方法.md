---
title: 技巧：Kuberntes 中无法删除 PV 的解决方法
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-09 14:01:13
tags:
---

技巧：Kuberntes 中无法删除 PV 的解决方法
一 背景
系统内有一个已经不再使用的 PV ，已经删除了与其关联的 Pod 及 PVC ，并对其执行了删除命令，但是无法正常删除，一直出于如下状态：

```
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                                    STORAGECLASS          REASON   AGE
pv-nfs-gysl   1Gi        RWO            Recycle          Terminating   default/www-vct-statefulset-pvc-gysl-0   managed-nfs-storage            22h
1
2
3
二 解决方法
$ kubectl patch pv pv-nfs-gysl -p '{"metadata":{"finalizers":null}}'
persistentvolume/pv-nfs-gysl patched
$ kubectl get pv
No resources found.
```


通过系统帮助信息，我们可以获取patch的简要使用说明：

patch： 使用 strategic merge patch 更新一个资源的 field(s)。
