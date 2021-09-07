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

$ kubectl create -f role.yaml
$ kubectl create -f role-bind.yaml

接下来该怎么做？和前面一样的，我们只需要拿到cnych这个ServiceAccount的token就可以登录Dashboard了：

```shell
➜ kubectl get secret -n kube-system |grep cnych
cnych-token-8w76h                                kubernetes.io/service-account-token   3      2m28s

kind-k8s/opt/nginx-ingress
➜ kubectl get secret cnych-token-8w76h -o jsonpath={.data.token} -n kube-syste
m |base64 -d
eyJhbGciOiJSUzI1NiIsImtpZCI6ImRfREZOWDlTaFp4alZ2bUF2ZUtkR0J4azVyalQ5VFZONXR6N3p3eGRTSmsifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjbnljaC10b2tlbi04dzc2aCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJjbnljaCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6Ijg0NjFiYTM1LTZmZTMtNDQ0Mi1hODU4LTE2YjBkNzgyM2FjOCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTpjbnljaCJ9.bWJhpGhhXZGODPaF9nRuY7HLdEAy3FBkYRpKDXi9gWS92Z0YhfazLWM2YO1flEJ1oMcRwKz5QMBLoUbpM9FoTpxF6CWyfoIRMUBaJW-ktmReyJQ9PDufqr03ulSahjwSMw85oOi9-WThiv0RQgQVmRUMBgpRadPlemO_cAt-u-UmBnXS50waBq48VNbSbwbbxgmI7cixcrRV74jN7aMg1ra9Xt15gzCdjxFu-FBMHNUuUVAOVX5s_D7iwL4P6qFqcNSg0DWC9VlGasrwZgx-9h7Bij4KF81NauRTMT2xkxwxIme7K-0HcLGtcWxoh6QrSYbuIGSirDpsVbqksR1Cqw
```

# kubernetes 登陆为空解决办法

 原创

创建一个群集管理服务帐户
在此步骤中，我们将为仪表板创建服务帐户并获取其凭据。

运行以下命令：

此命令将在默认名称空间中为仪表板创建服务帐户

```html
kubectl create serviceaccount dashboard -n default

1.2.
```

将集群绑定规则添加到您的仪表板帐户

```html
kubectl create clusterrolebinding dashboard-admin -n default  --clusterrole=cluster-admin  --serviceaccount=default:dashboard

1.2.
```

使用以下命令复制仪表板登录所需的令牌：

```html
kubectl get secret $(kubectl get serviceaccount dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

1.2.
```

复制令牌，然后通过选择令牌选项将其粘贴到仪表板登录页面中

![image-20210907095803327](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210907095803327.png)

❯ kubectl get node
NAME                       STATUS   ROLES                  AGE   VERSION
multi-node-control-plane   Ready    control-plane,master   75m   v1.21.1
multi-node-worker          Ready    <none>                 74m   v1.21.1

kind-k8s/opt/nginx-ingress
➜ kubectl label nodes multi-node-worker ingress-ready=true
node/multi-node-worker labeled

kind-k8s/opt/nginx-ingress
➜ kubectl label nodes multi-node-control-plane ingress-ready=true
node/multi-node-control-plane labeled

