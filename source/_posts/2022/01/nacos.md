---
title: 添加readmore
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
## 关于在k8s-v1.20以上版本使用nfs作为storageclass出现selfLink was empty, can‘t make reference

在使用nfs创建storageclass 实现存储的动态加载
分别创建 rbac、nfs-deployment、nfs-storageclass之后都正常运行
但在创建pvc时一直处于pending状态
kubectl describe pvc test-claim 查看pvc信息提示如下

```powershell
Name:          test-claim
Namespace:     default
StorageClass:  managed-nfs-storage
Status:        Pending
Volume:        
Labels:        <none>
Annotations:   volume.beta.kubernetes.io/storage-class: managed-nfs-storage
               volume.beta.kubernetes.io/storage-provisioner: fuseim.pri/ifs
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      
Access Modes:  
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                Age               From                         Message
  ----    ------                ----              ----                         -------
  Normal  ExternalProvisioning  2s (x4 over 19s)  persistentvolume-controller  waiting for a volume to be created, either by external provisioner "fuseim.pri/ifs" or manually created by system administrator
```

查找无果然后查看nfs-pod状态，报错如下

```powershell
provision "default/test-claim" class "managed-nfs-storage": unexpected error getting claim reference: selfLink was empty, can't make reference
```

selfLink was empty 在k8s集群 v1.20之前都存在，在v1.20之后被删除，需要在`/etc/kubernetes/manifests/kube-apiserver.yaml` 添加参数
增加 `- --feature-gates=RemoveSelfLink=false`

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --feature-gates=RemoveSelfLink=false
```

添加之后使用kubeadm部署的集群会自动加载部署pod

```c
kubeadm安装的apiserver是Static Pod，它的配置文件被修改后，立即生效。
Kubelet 会监听该文件的变化，当您修改了 /etc/kubenetes/manifest/kube-apiserver.yaml 文件之后，kubelet 将自动终止原有的 kube-apiserver-{nodename} 的 Pod，并自动创建一个使用了新配置参数的 Pod 作为替代。
如果您有多个 Kubernetes Master 节点，您需要在每一个 Master 节点上都修改该文件，并使各节点上的参数保持一致。
```

这里需注意如果api-server启动失败 需重新在执行一遍

```powershell
kubectl apply -f /etc/kubernetes/manifests/kube-apiserver.yaml
```

![image-20220106142209114](https://s2.loli.net/2022/01/06/F68w7SYsxVLreuM.png)

nacos-ingeress:

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nacos-headless-http
  namespace: bcs-dev
  annotations:
    kubernetes.io/ingress.class: traefik  
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: nacos-server.bcs236.com 
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: nacos-headless
            port:
              number: 8848

```

```
10.0.37.144 nacos-server.bcs236.com 
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nacos-headless-http
  namespace: bcs-dev
  annotations:
    kubernetes.io/ingress.class: traefik  
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: nacos-server.bcs227.com 
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: nacos-headless
            port:
              number: 8848
```

```
11.0.37.100 nacos-server.bcs227.com
```

