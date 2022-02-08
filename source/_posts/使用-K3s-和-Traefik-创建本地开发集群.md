---
title: 使用 K3s 和 Traefik 创建本地开发集群
date: 2021-09-08 09:37:55
tags:
- devops
categories: 
- devops
---

![](https://ask.qcloudimg.com/http-save/yehe-1487868/kv3k9ji3jk.png?imageView2/2/w/1620)

完整的 Kubernetes 集群往往非常复杂，需要较高的资源，往往我们在开发期间需要一个完整的 Kubernetes 来运行我们的应用，但是并不要求达到生产级别的集群，本文我们将探讨几种本地轻松配置 Kubernetes 集群的方法。

<!--more-->

## **本地 Kubernetes 集群**

我们先来回顾几种适合在我们自己的电脑上运行 Kubernetes 集群的方案。

### **Minikube**

Minikube 是 Kubernetes 项目文档中建议使用的一种解决方案，它用一个单节点集群部署一个虚拟机，我们需要付出虚拟化的代价，主机的最低要求 2CPU、2G内存、20G 存储空间。

这是一种简单有效的学习 kubectl 命令的方法，但是单节点会有一些的不方便的地方，但 Minikube 团队最近引入了多节点作为实验性功能，来帮助解决这个问题。

### **Kind**

Kind 是 Kubernetes SIG 的另一种用于本地部署集群的方法。他的核心实现是让整个集群运行在 Docker 容器中。因此，它比 Minikube 更容易设置和更快启动。它支持单个节点或多 master 以及多工作节点。

Kind 是为一致性测试和用于 CI 管道而创建的，提供了一些不错的功能，比如可以直接在集群内部加载 Docker 镜像，而不需要推送到外部镜像仓库。

### **k3s / k3d**

K3s 是一个轻量级的集群，为了实现这种极简主义，做了一些取舍。

-   集群的默认存储是使用 SQLite 而不是 Etcd
-   所有的控制平面组件都封装在一个单一的二进制中
-   控制外部依赖的数量

K3d 是一个允许我们在 Docker 容器内运行 k3s 的工具，就像 Kind 一样。

## **应该选哪个？**

我个人的需求是：

-   集群要快速启动和停止
-   不同的集群可以并排运行
-   集群必须使用最少的系统资源

对我来说，最适合的是 k3d，因为它很容易配置，它在 Docker 中运行，消耗的资源很少，而且开箱即用功能齐全。

现在让我们来看看如何使用 k3d 建立一个集群。

## **使用 k3d 启动集群**

首先先获取 k3d，通过 https://github.com/rancher/k3d#get 获取安装方式。

**创建新的 k3d 集群**

直接运行下面的命令即可创建一个新的集群：

$ k3d cluster create devcluster \\
\--api\-port 127.0.0.1:6443 \\
\-p 80:80@loadbalancer \\
\-p 443:443@loadbalancer \\
\--k3s\-server\-arg "--no-deploy=traefik"
INFO\[0000\] Created network 'k3d-devcluster'             
INFO\[0000\] Created volume 'k3d-devcluster-images'       
INFO\[0001\] Creating node 'k3d-devcluster-server-0'      
INFO\[0016\] Pulling image 'docker.io/rancher/k3s:v1.18.9-k3s1' 
INFO\[0040\] Creating LoadBalancer 'k3d-devcluster-serverlb' 
INFO\[0056\] Pulling image 'docker.io/rancher/k3d-proxy:v3.1.3' 
INFO\[0064\] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access 
INFO\[0066\] Successfully added host record to /etc/hosts in 2/2 nodes and to the CoreDNS ConfigMap 
INFO\[0066\] Cluster 'devcluster' created successfully!   
INFO\[0066\] You can now use it like this:                
kubectl cluster\-info

上面的创建集群命令有几个需要注意的地方：

-   我们将本地主机的80和443端口映射到 k3s 虚拟[负载均衡](https://cloud.tencent.com/product/clb?from=10680)器上，这可以让我们能够直接从本地主机上访问到 ingress 资源。
-   群集的部署没有使用默认的 Traefik Ingress 控制器。

为什么要禁用 Traefik？因为我们可能想使用另一个 Ingress 控制器，或者因为 k3s 默认是与 Traefik 1 绑定在一起的，后面我们会安装Traefik 2 版本。

**获取凭证**

运行下面的命令获取你的凭证，将其保存在文件中并导出到你的环境中：

$ mkdir \-p $HOME/k3d
$ k3d kubeconfig get devcluster \> $HOME/k3d/kubeconfig
$ export KUBECONFIG\=$HOME/k3d/kubeconfig

通过运行一个简单的 Kubectl 命令来测试你是否可以访问集群。

$ kubectl cluster\-info
Kubernetes master is running at \[https://127.0.0.1:6443\](https://127.0.0.1:6443/)
CoreDNS is running at \[https://127.0.0.1:6443/api/v1/namespaces/kube\-system/services/kube\-dns:dns/proxy\](https://127.0.0.1:6443/api/v1/namespaces/kube\-system/services/kube\-dns:dns/proxy)
Metrics\-server is running at \[https://127.0.0.1:6443/api/v1/namespaces/kube\-system/services/https:metrics\-server:/proxy\](https://127.0.0.1:6443/api/v1/namespaces/kube\-system/services/https:metrics\-server:/proxy)

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

**安装 Traefik 2**

我们可以直接使用 Helm 来快速安装 Traefik 2：

$ helm repo add traefik https://containous.github.io/traefik\-helm\-chart
"traefik" has been added to your repositories
$ helm repo list
NAME    URL                                            
traefik https://containous.github.io/traefik\-helm\-chart
$ helm install traefik traefik/traefik
NAME: traefik
LAST DEPLOYED: Sun Oct 18 01:18:16 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

部署完成后检查 Traefik 是否正常工作，我们可以通过 port-forward dashboard 来验证：

$ kubectl port\-forward $(kubectl get pods \--selector "app.kubernetes.io/name=traefik" \--output\=name) \--address 0.0.0.0 9000:9000

然后在浏览器中访问 http://localhost:9000/dashboard/，正常可以访问到 traefik 的 dashboard 页面。

![image-20210908094953693](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210908094953693.png)

**部署应用**

接下来部署一个简单的应用程序来验证我们的 Ingress Controller 是否正确配置了，这里我们使用 whoami 应用程序：

$ kubectl create deploy whoami \--image containous/whoami
deployment.apps/whoami created
$ kubectl expose deploy whoami \--port 80
service/whoami exposed

然后我们定义一个 Ingress 规则来使用我们新的 Traefik，Traefik 既能读取自己的 CRD IngressRoute，也能读取传统的 Ingress 资源。

apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: whoami
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  rules:
  \- http:
      paths:
      \- path: /
        backend:
          serviceName: whoami
          servicePort: 80

在这个例子中，我们在 HTTP 和 HTTPs 两个入口点上暴露了 whoami 服务，每一个 URL 都会被发送到该服务上，我们可以在 Traefik Dashboard 上看到新的路由器。

![image-20210908095023986](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210908095023986.png)

要测试这个应用我们可以直接在浏览器中访问：https://localhost/ 即可，这是因为上面我们安装 Traefik 的时候自动创建了一个 LoadBalancer 的 Service 服务。

$ kubectl get svc
NAME         TYPE           CLUSTER\-IP    EXTERNAL\-IP   PORT(S)                      AGE
kubernetes   ClusterIP      10.43.0.1     <none\>        443/TCP                      13m
traefik      LoadBalancer   10.43.32.29   172.19.0.2    80:31005/TCP,443:31507/TCP   7m25s
whoami       ClusterIP      10.43.98.9    <none\>        80/TCP                       4m5s

![image-20210908095053168](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210908095053168.png)

## **总结**

从上面示例可以看出创建一个开发级别的集群是非常简单的，而且还有更多的功能可以挖掘，包括 k3s 的 Helm charts 自动部署或者使用 Golang API 来管理啊 Kind 的集群，快使用用一个功能齐全的 Kubernetes 集群取代你的老式 Docker-compose 吧。

> 原文链接：https://codeburst.io/creating-a-local-development-kubernetes-cluster-with-k3s-and-traefik-proxy-7a5033cb1c2d

