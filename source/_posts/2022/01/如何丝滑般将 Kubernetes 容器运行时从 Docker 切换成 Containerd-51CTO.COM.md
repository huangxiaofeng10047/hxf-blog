
---
title: 如何丝滑升级k8s到containerd
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
[![](https://s6.51cto.com/oss/202108/18/89de1238cdf68d84f1e84d56b7eacc52.png)](https://s6.51cto.com/oss/202108/18/89de1238cdf68d84f1e84d56b7eacc52.png)

前面我们了解了 containerd 的发展历史和基本使用方式，本节我们就来尝试下使用 containerd 来作为 Kubernetes 集群的容器运行时。

前面我们安装的集群默认使用的是 Docker 作为容器运行时，那么应该如何将容器运行时从 Docker 切换到 containerd 呢?

### 维护节点

首先标记需要切换的节点为维护模式，强制驱逐节点上正在运行的 Pod，这样可以最大程度降低切换过程中影响应用的正常运行，比如我们先将 node1 节点切换到 containerd。

首先使用 kubectl cordon 命令将 node1 节点标记为 unschedulable 不可调度状态：

```
# 将 node1 标记为 unschedulable 
➜  ~ kubectl cordon node1 
node/node1 cordoned 
➜  ~ kubectl get nodes 
NAME     STATUS                     ROLES    AGE   VERSION 
master   Ready                      master   85d   v1.19.11 
node1    Ready,SchedulingDisabled   <none>   85d   v1.19.11 
node2    Ready                      <none>   85d   v1.19.11 
```

执行完上面的命令后，node1 节点变成了一个 SchedulingDisabled 状态，表示不可调度，这样新创建的 Pod 就不会调度到当前节点上来了。

接下来维护 node1 节点，使用 kubectl drain 命令来维护节点并驱逐节点上的 Pod：

```
# 维护 node1 节点，驱逐 Pod 
➜  ~ kubectl drain node1  
node/node1 already cordoned 
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-flannel-ds-mzdgl, kube-system/kube-proxy-vddh9, lens-metrics/node-exporter-2g4hr 
evicting pod "kiali-85c8cdd5b5-27cwv" 
evicting pod "jenkins-587b78f5cd-9gvn8" 
evicting pod "argocd-application-controller-0" 
pod/argocd-application-controller-0 evicted 
pod/kiali-85c8cdd5b5-27cwv evicted 
pod/jenkins-587b78f5cd-9gvn8 evicted 
node/node1 evicted 
```

上面的命令会强制将 node1 节点上的 Pod 进行驱逐，我们加了一个 --ignore-daemonsets 的参数可以用来忽略 DaemonSet 控制器管理的 Pods，因为这些 Pods 不用驱逐到其他节点去，当节点驱逐完成后接下来我们就可以来对节点进行维护操作了，除了切换容器运行时可以这样操作，比如我们需要变更节点配置、升级内核等操作的时候都可以先将节点进行驱逐，然后再进行维护。

### 切换 containerd

接下来停掉 docker、containerd 和 kubelet：

```
➜  ~ systemctl stop kubelet 
➜  ~ systemctl stop docker 
➜  ~ systemctl stop containerd 
```

因为我们安装的 Docker 默认安装使用了 containerd 作为后端的容器运行时，所以不需要单独安装 containerd 了，当然你也可以将 Docker 和 containerd 完全卸载掉，然后重新安装，这里我们选择直接使用之前安装的 containerd。

因为 containerd 中默认已经实现了 CRI，但是是以 plugin 的形式配置的，以前 Docker 中自带的 containerd 默认是将 CRI 这个插件禁用掉了的(使用配置 disabled\_plugins = \["cri"\])，所以这里我们重新生成默认的配置文件来覆盖掉：

```
➜  ~ containerd config default > /etc/containerd/config.toml 
```

前面我们已经介绍过上面的配置文件了，首先我们修改默认的 pause 镜像为国内的地址，替换 \[plugins."io.containerd.grpc.v1.cri"\] 下面的 sandbox\_image：

```
[plugins."io.containerd.grpc.v1.cri"] 
  sandbox_image = "registry.aliyuncs.com/k8sxio/pause:3.2" 
  ...... 
```

同样再配置下镜像仓库的加速器地址：

```
[plugins."io.containerd.grpc.v1.cri".registry] 
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors] 
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"] 
      endpoint = ["https://bqr1dr1n.mirror.aliyuncs.com"] 
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"] 
      endpoint = ["https://registry.aliyuncs.com/k8sxio"] 
```

接下来修改 kubelet 配置，将容器运行时配置为 containerd，打开 /etc/sysconfig/kubelet 文件，在该文件中可以添加一些额外的 kubelet 启动参数，配置如下所示：

```
KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock" 
```

上面的配置中我们增加了两个参数，--container-runtime 参数是用来指定使用的容器运行时的，可选值为 docker 或者 remote，默认是 docker，由于我们这里使用的是 containerd 这种容器运行时，所以配置为 remote 值(也就是除 docker 之外的容器运行时都应该指定为 remote)，然后第二个参数 --container-runtime-endpoint 是用来指定远程的运行时服务的 endpiont 地址的，在 Linux 系统中一般都是使用 unix 套接字的形式，比如这里我们就是指定连接 containerd 的套接字地址 unix:///run/containerd/containerd.sock。

-   其实还应该配置一个 --image-service-endpoint 参数用来指定远程 CRI 的镜像服务地址，如果没有指定则默认使用 --container-runtime-endpoint 的值了，因为 CRI 都会实现容器和镜像服务的。

配置完成后重启 containerd 和 kubelet 即可：

```
➜  ~ systemctl daemon-reload 
➜  ~ systemctl restart containerd 
➜  ~ systemctl restart kubelet 
```

重启完成后查看节点状态是否正常：

```
➜  ~ kubectl get nodes -o wide 
NAME     STATUS                     ROLES    AGE   VERSION    INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION                CONTAINER-RUNTIME 
master   Ready                      master   85d   v1.19.11   192.168.31.30    <none>        CentOS Linux 7 (Core)   3.10.0-1160.25.1.el7.x86_64   docker://19.3.9 
node1    Ready,SchedulingDisabled   <none>   85d   v1.19.11   192.168.31.95    <none>        CentOS Linux 7 (Core)   3.10.0-1160.25.1.el7.x86_64   containerd://1.4.4 
node2    Ready                      <none>   85d   v1.19.11   192.168.31.215   <none>        CentOS Linux 7 (Core)   3.10.0-1160.25.1.el7.x86_64   docker://19.3.9 
```

获取节点的时候加上 -o wide 可以查看节点的更多信息，从上面对比可以看到 node1 节点的容器运行时已经切换到 containerd://1.4.4 了。

最后把 node1 节点重新加回到集群中来允许调度 Pod 资源：

```
➜  ~ kubectl uncordon node1 
node/node1 uncordoned 
➜  ~ kubectl get nodes 
NAME     STATUS   ROLES    AGE   VERSION 
master   Ready    master   85d   v1.19.11 
node1    Ready    <none>   85d   v1.19.11 
node2    Ready    <none>   85d   v1.19.11 
```

用同样的方法再去处理其他节点即可将整个集群切换成容器运行时 containerd 了。

### crictl

现在我们可以 node1 节点上使用 ctr 命令来管理 containerd，查看多了一个名为 k8s.io 的命名空间：

```
➜  ~ ctr ns ls 
NAME   LABELS 
k8s.io 
moby 
```

上文我们已经介绍 kubernetes 集群对接的 containerd 所有资源都在 k8s.io 的命名空间下面，而 docker 的则默认在 moby 下面，当然现在 moby 下面没有任何的数据了，但是在 k8s.io 命名空间下面就有很多镜像和容器资源了：

```
➜  ~ ctr -n moby c ls 
CONTAINER    IMAGE    RUNTIME 
➜  ~ ctr -n moby i ls 
REF TYPE DIGEST SIZE PLATFORMS LABELS 
➜  ~ ctr -n moby t ls 
TASK    PID    STATUS 
ctr -n k8s.io i ls -q 
docker.io/library/busybox:latest 
docker.io/library/busybox@sha256:0f354ec1728d9ff32edcd7d1b8bbdfc798277ad36120dc3dc683be44524c8b60 
quay.io/coreos/flannel:v0.14.0 
quay.io/coreos/flannel@sha256:4a330b2f2e74046e493b2edc30d61fdebbdddaaedcb32d62736f25be8d3c64d5 
registry.aliyuncs.com/k8sxio/pause:3.2 
...... 
```

我们当然可以直接使用 ctr 命令来直接管理镜像或容器资源，但是我们在使用过程中明显可以感觉到该工具没有 docker CLI 方便，从使用便捷性和功能性上考虑，我们更推荐使用 crictl 作为管理工具，crictl 为 CRI 兼容的容器运行时提供 CLI，这允许 CRI 运行时开发人员在无需设置 Kubernetes 组件的情况下调试他们的运行时。

接下来我们就先简单介绍下如何使用 crictl 工具来提升管理容器运行时的效率。

### 安装

首先我们需要先安装 crictl 工具，直接从 cri-tools 的 release 页面下载对应的二进制包，解压放入 PATH 路径下即可：

```
➜  ~ VERSION="v1.22.0" 
➜  ~ wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz 
# 如果有限制，也可以替换成下面的 URL 加速下载 
# wget https://download.fastgit.org/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz 
➜  ~ tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin 
➜  ~ rm -f crictl-$VERSION-linux-amd64.tar.gz 
➜  ~ crictl -v 
crictl version v1.22.0 
```

到这里证明 crictl 工具安装成功了。

### 用法

crictl 安装完成后，接下来我们来了解下该工具的一些常见使用方法。

首先需要修改下默认的配置文件，默认为 /etc/crictl.yaml，在文件中指定容器运行时和镜像的 endpoint 地址，内容如下所示：

```
runtime-endpoint: unix:///var/run/containerd/containerd.sock 
image-endpoint: unix:///var/run/containerd/containerd.sock 
debug: false 
pull-image-on-create: false 
disable-pull-on-run: false 
```

配置完成后就可以使用 crictl 命令了。

### 获取 Pod 列表

通过 crictl pods 命令可以获取当前节点上运行的 Pods 列表，如下所示：

```
➜  ~ crictl pods 
POD ID              CREATED             STATE               NAME                       NAMESPACE           ATTEMPT             RUNTIME 
cb18081b33933       39 minutes ago      Ready               kube-flannel-ds-mzdgl      kube-system         1                   (default) 
95d6004c55902       40 minutes ago      Ready               node-exporter-2g4hr        lens-metrics        1                   (default) 
cfae80b3209db       40 minutes ago      Ready               kube-proxy-vddh9           kube-system         1                   (default) 
99ac2583da87f       40 minutes ago      Ready               jenkins-587b78f5cd-dfzns   kube-ops            0                   (default) 
07ebdc51f1def       45 minutes ago      NotReady            node-exporter-2g4hr        lens-metrics        0                   (default) 
bec027b98f194       45 minutes ago      NotReady            kube-proxy-vddh9           kube-system         0                   (default) 
b44b5ec385053       45 minutes ago      NotReady            kube-flannel-ds-mzdgl      kube-system         0                   (default) 
```

还可以使用 --name 参数获取指定的 Pod：

```
➜  ~ crictl pods  
POD ID              CREATED             STATE               NAME                    NAMESPACE           ATTEMPT             RUNTIME 
cb18081b33933       About an hour ago   Ready               kube-flannel-ds-mzdgl   kube-system         1                   (default) 
```

同样也可以根据标签来筛选 Pod 列表：

```
➜  ~ crictl pods  
POD ID              CREATED             STATE               NAME                    NAMESPACE           ATTEMPT             RUNTIME 
cb18081b33933       About an hour ago   Ready               kube-flannel-ds-mzdgl   kube-system         1                   (default) 
```

### 获取镜像列表

使用 crictl images 命令可以获取所有的镜像：

```
➜  ~ crictl images 
IMAGE                                     TAG                 IMAGE ID            SIZE 
docker.io/jenkins/jenkins                 lts                 3b4ec91827f28       303MB 
docker.io/library/busybox                 latest              69593048aa3ac       771kB 
quay.io/coreos/flannel                    v0.14.0             8522d622299ca       21.1MB 
quay.io/prometheus/node-exporter          v1.0.1              0e0218889c33b       13MB 
registry.aliyuncs.com/k8sxio/kube-proxy   v1.19.11            732e0635ac9e0       49.3MB 
registry.aliyuncs.com/k8sxio/pause        3.2                 80d28bedfe5de       300kB 
```

同样在命令后面可以加上 -v 参数来显示镜像的详细信息：

```
➜  ~ crictl images -v 
ID: sha256:3b4ec91827f28ed482b08f6e379c56ea2308967d10aa4f458442c922e0771f87 
RepoTags: docker.io/jenkins/jenkins:lts 
RepoDigests: docker.io/jenkins/jenkins@sha256:abcd55c9f19c85808124a4d82e3412719cd5c511c03ebd7d4210e9fa9e8f1029 
Size: 302984002 
Username: jenkins 
 
ID: sha256:69593048aa3acfee0f75f20b77acb549de2472063053f6730c4091b53f2dfb02 
RepoTags: docker.io/library/busybox:latest 
RepoDigests: docker.io/library/busybox@sha256:0f354ec1728d9ff32edcd7d1b8bbdfc798277ad36120dc3dc683be44524c8b60 
Size: 770886 
 
...... 
```

### 获取容器列表

使用 crictl ps 命令可以获取正在运行的容器列表：

```
➜  ~ crictl ps 
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID 
c8474738e4587       3b4ec91827f28       About an hour ago   Running             jenkins             0                   99ac2583da87f 
0f9c826f87ef8       8522d622299ca       About an hour ago   Running             kube-flannel        1                   cb18081b33933 
da444f718d37b       0e0218889c33b       About an hour ago   Running             node-exporter       1                   95d6004c55902 
a484a8a69ea59       732e0635ac9e0       About an hour ago   Running             kube-proxy          1                   cfae80b3209db 
```

还有更多其他可选参数，可以通过 crictl ps -h 获取，比如显示最近创建的两个容器：

```
➜  ~ crictl ps -n 2 
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID 
c8474738e4587       3b4ec91827f28       About an hour ago   Running             jenkins             0                   99ac2583da87f 
0f9c826f87ef8       8522d622299ca       About an hour ago   Running             kube-flannel        1                   cb18081b33933 
```

使用 -s 选项按照状态进行过滤：

```
➜  ~ crictl ps -s Running 
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID 
c8474738e4587       3b4ec91827f28       About an hour ago   Running             jenkins             0                   99ac2583da87f 
0f9c826f87ef8       8522d622299ca       About an hour ago   Running             kube-flannel        1                   cb18081b33933 
da444f718d37b       0e0218889c33b       About an hour ago   Running             node-exporter       1                   95d6004c55902 
a484a8a69ea59       732e0635ac9e0       About an hour ago   Running             kube-proxy          1                   cfae80b3209db 
```

### 在容器中执行命令

crictl 也有类似 exec 的命令支持，比如在容器 ID 为 c8474738e4587 的容器中执行一个 date 命令：

```
➜  ~ crictl exec -it c8474738e4587 date 
Tue 17 Aug 2021 08:23:02 AM UTC 
```

### 输出容器日志

还可以获取容器日志信息：

```
➜  ~ crictl logs c8474738e4587 
...... 
2021-08-17 07:19:51.846+0000 [id=155]   INFO    hudson.model.AsyncPeriodicWork#lambda$doRun$0: Started Periodic background build discarder 
2021-08-17 07:19:51.854+0000 [id=155]   INFO    hudson.model.AsyncPeriodicWork#lambda$doRun$0: Finished Periodic background build discarder. 6 ms 
2021-08-17 08:19:51.846+0000 [id=404]   INFO    hudson.model.AsyncPeriodicWork#lambda$doRun$0: Started Periodic background build discarder 
2021-08-17 08:19:51.848+0000 [id=404]   INFO    hudson.model.AsyncPeriodicWork#lambda$doRun$0: Finished Periodic background build discarder. 1 ms 
```

和 kubectl logs 类似于，还可以使用 -f 选项来 Follow 日志输出，--tail N 也可以指定输出最近的 N 行日志。

### 资源统计

使用 crictl stats 命令可以列举容器资源的使用情况：

```
➜  ~ crictl stats 
CONTAINER           CPU %               MEM                 DISK                INODES 
0f9c826f87ef8       0.00                21.2MB              0B                  17 
a484a8a69ea59       0.00                23.55MB             12.29kB             25 
c8474738e4587       0.08                413.2MB             3.338MB             12 
da444f718d37b       0.00                14.46MB             0B                  16 
```

此外镜像和容器相关的一些操作也都支持，比如：

-   拉取镜像：crictl pull
-   运行 Pod：crictl runp
-   运行容器：crictl run
-   启动容器：crictl start
-   删除容器：crictl rm
-   删除镜像：crictl rmi
-   删除 Pod：crictl rmp
-   停止容器：crictl stop
-   停止 Pod：crictl stopp
-   ......

更多信息请参考 https://github.com/kubernetes-sigs/cri-tools。

### CLI 对比

前面我们了解了围绕镜像、容器和 Pod 可以使用 docker、ctr、crictl 这些命令行工具进行管理，接下来我们就来比较下这几个常用命令的使用区别。

[![](https://s5.51cto.com/oss/202108/18/9d03d3c775ffec4be0357ba86ffd1efe.png)](https://s5.51cto.com/oss/202108/18/9d03d3c775ffec4be0357ba86ffd1efe.png)

需要注意的是通过 ctr containers create 命令创建的容器只是一个静态的容器，所以还需要通过 ctr task start 来启动容器进程。当然，也可以直接使用 ctr run 命令来创建并运行容器。在进入容器操作时，与 docker 不同的是，必须在 ctr task exec 命令后指定 --exec-id 参数，这个 id 可以随便写，只要唯一就行。另外，ctr 没有 stop 容器的功能，只能暂停(ctr task pause)或者杀死(ctr task kill)容器。

另外要说明的是 crictl pods 列出的是 Pod 的信息，包括 Pod 所在的命名空间以及状态。crictl ps 列出的是应用容器的信息，而 docker ps 列出的是初始化容器(pause 容器)和应用容器的信息，初始化容器在每个 Pod 启动时都会创建，通常不会关注，所以 crictl 使用起来更简洁明了一些。

### 日志配置

docker 和 containerd 除了在常用命令上有些区别外，在容器日志及相关参数配置方面也存在一些差异。

当使用 Docker 作为 Kubernetes 容器运行时的时候，容器日志的落盘是由 Docker 来完成的，日志被保存在类似 /var/lib/docker/containers/ 的目录下面，kubelet 会在 /var/log/pods 和 /var/log/containers 下面创建软链接，指向容器日志目录下的容器日志文件。对应的日志相关配置可以通过配置文件进行指定，如下所示：

```
{ 
    "log-driver": "json-file", 
    "log-opts": { 
        "max-size": "100m", 
        "max-file: "10" 
    } 
} 
```

而当使用 containerd 作为 Kubernetes 容器运行时的时候，容器日志的落盘则由 kubelet 来完成了，被直接保存在 /var/log/pods/ 目录下面，同时在 /var/log/containers 目录下创建软链接指向日志文件。同样日志配置则是通过 kubelet 参数中进行指定的，如下所示：

所以如果我们有进行日志收集理论上来说两种方案都是兼容的，基本上不用改动。

当然除了这些差异之外，可能对于我们来说镜像构建这个环节是我们最需要关注的了。切换到 containerd 之后，需要注意 docker.sock 不再可用，也就意味着不能再在容器里面执行 docker 命令来构建镜像了。所以接下来需要和大家介绍几种不需要使用 docker.sock 也可以构建镜像的方法。