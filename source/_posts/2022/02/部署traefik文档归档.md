---
title: 部署traefik文档归档
description: '部署traefik文档归档'
date: 2022-02-09 09:06:13
tags: 
 - traefik
---

helm部署脚本：

traefik-helm-chart

创建自定义文件：

如下图所示value-prod.yaml

```
service:
  type: ClusterIP

ingressRoute:
  dashboard:
    enabled: false


ports:
  web:
    hostPort: 80
  websecure:
    hostPort: 443
  traefik:
    port: 8080
    hostPort: 8080
    exposedPort: 8080
    expose: true
  mysql:
    hostPort: 3307
    port: 3307
    exposedPort: 3307
    expose: true
additionalArguments:
  - "--serversTransport.insecureSkipVerify=true"
  - "--api.insecure=true"
  - "--api.dashboard=true"
tolerations:   # kubeadm 安装的集群默认情况下master是有污点，需要容忍这个污点才可以部署
- key: "node-role.kubernetes.io/master"
  operator: "Equal"
  effect: "NoSchedule"
nodeSelector:   # 固定到master1节点（该节点才可以访问外网）
  kubernetes.io/hostname: "master1"
```

创建命令：

`helm install --namespace kube-system traefik ./traefik/ -f ./values-prod.yaml`

升级命令：

`helm upgrade --namespace kube-system traefik ./traefik/ -f ./values-prod.yaml`

部署完成后，即可通过8080端口访问到dashboard地址。

