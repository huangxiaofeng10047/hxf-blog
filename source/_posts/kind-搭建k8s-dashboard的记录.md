---
title: kind 搭建k8s+dashboard的记录
date: 2021-09-07 09:20:05
tags:
- drone
- ci 
categories: 
- devops
---

1.KIND官方文档：https://kind.sigs.k8s.io/docs/user/quick-start/

（1）安装go：https://golang.org/dl/

（2）安装kind

（3）安装docker：https://docs.docker.com/engine/install/ubuntu/

 (4) 在主机上作为工具去操作kind中的kubectl， 需要安装kubuctl，教程： https://www.kubernetes.org.cn/installkubectl 

2.用kind创建K8S集群：

（1）编写好 yaml`文件：如：kind-example-config.yaml`

```
# this config file contains all config fields with comments
# NOTE: this is not a particularly useful config file
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  # WARNING: It is _strongly_ recommended that you keep this the default
  # (127.0.0.1) for security reasons. However it is possible to change this.
  apiServerAddress: "192.168.50.16"
  # By default the API server listens on a random open port.
  # You may choose a specific port but probably don't need to in most cases.
  # Using a random port makes it easier to spin up multiple clusters.
  apiServerPort: 6443
# patch the generated kubeadm config with some extra settings
kubeadmConfigPatches:
- |
  apiVersion: kubelet.config.k8s.io/v1beta1
  kind: KubeletConfiguration
  evictionHard:
    nodefs.available: "0%"
# patch it further using a JSON 6902 patch
kubeadmConfigPatchesJSON6902:
- group: kubeadm.k8s.io
  version: v1beta2
  kind: ClusterConfiguration
  patch: |
    - op: add
      path: /apiServer/certSANs/-
      value: my-hostname
# 1 control plane node and 3 workers
nodes:
# the control plane node config
- role: control-plane
  extraPortMappings:
  -   containerPort: 30001
      hostPort:  3001
      listenAddress: "0.0.0.0"
      protocol:  tcp
  -   containerPort: 30002
      hostPort:  3002
      listenAddress: "0.0.0.0"
      protocol:  tcp
  -   containerPort: 30003
      hostPort:  3003
      listenAddress: "0.0.0.0"
      protocol:  tcp    
  -   containerPort: 30004
      hostPort:  3004
      listenAddress: "0.0.0.0"
      protocol:  tcp        
# the three workers
- role: worker
```

创建集群：

`kind create cluster --config kind-example-config.yaml --name multi-node`

安装dashboard：

（1）参考安装教程:https://github.com/kubernetes/dashboard：

　   1。。下载文件：wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml

　　 2.。。修改文件，映射端口：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210907092238533.png" alt="image-20210907092238533" style="zoom:150%;" />

 3. 部署文件

    　`kubectl apply -f recommended.yaml`

通过之间创建kind集群的时候映射的端口如3004--》30004，我们就可以通过http：//主机IP：3004访问dashboard了

一定要用https在chrome下

https://192.168.50.16:3004/#/workloads?namespace=default

第一步需要输入token

生成token的命令如下：

 `kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')`

![image-20210907092526649](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210907092526649.png)

