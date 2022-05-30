---
title: minikube 安装 Kubernetes on WSL2 权威指南
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-27 11:15:52
tags:
---

- d、kubelet 都是通过 API Server 通信，支持 authentication/authorization
- Scheduler：负责资源的调度，按照预定的调度策略将 Pod 调度到相应的机器上
- Controller Manager：控制管理 Namespace、ServiceAccount、ResourceQuota、Replication、Volume、NodeLifecycle、Service、Endpoint、DaemonSet、Job、Cronjob、ReplicaSet、Deployment 等等
- etcd：high-available distributed key-value store，用于保存集群的状态，提供 watch for changes 功能
- Kubelet：负责维护容器的生命周期，通过 API Server 把状态告知 Master，同时负责 Volume (CVI) 和网络 (CNI) 的管理
- Kube-Proxy：网络代理和负载均衡，主要用于帮助 service 实现虚拟 IP
- Container Runtime：管理镜像，运行 Pod 和容器，最常用的是 Docker
- Registry：存储镜像
- DNS：为集群提供 DNS 服务（Kube-DNS、CoreDNS）
- Dashboard：提供 Web UI
- Container Resource Monitoring：cAdvisor + Kubelet、Prometheus、Google Cloud Monitoring
- Cluster-level Logging：Fluentd
- CNI：Container Network Interface（Flannel、Calico）
- CSI：Container Storage Interface
- Ingress Controller：为服务提供外网入口

Kubernetes 是 Go 语言编写的



# 2、Kubernetes 概念

- Pod：可以创建、调度、部署、管理的最小单位，Pod 包含一个或多个紧耦合的 container，并共享 hostname、IPC、network、storage 等
- ReplicaSet：确保 Pod 以指定的副本个数运行，和 Replication 的唯一区别是对选择器的支持不一样
- Deployment：用于管理 Pod、ReplicaSet，可以实现 Deploy/Scaling/Upgrade/Rollback
- Service：对外提供一个虚拟 IP，后端是一组有相同 Label 的 Pod，并在这些 Pod 之间做负载均衡（ClusterIP、NodePort、LoadBalancer 等几种配置），即负责转发数据到 Pod
- Ingress：链接多个 Service 作为统一入口，根据不同的路径，将数据转发到不同的 Service
- ConfigMap：用于解耦部署与配置的关系，即 Deployment、Pod 等不需要定义好配置，只需要指定对应的 ConfigMap，具体的内容由 ConfigMap 决定
- Secrets：ConfigMap 存储不敏感的信息，而 Secrets 用于存储敏感信息，Secrets 以加密的形式存储（可能是存在 etcd 中），当 Secrets 挂载到 Pod 时，会被解密，并且实质上是存在内存中，可以以文件的形式挂载

以上这些都需要通过 yaml 文件定义（这些文件也被称为 Manifest），然后通过 kubectl create -f xxx.yaml 启动

**总结下Kubernetes的基本概念：**

- Pod：K8s的基本运行单元
- ReplicaSet：Pod的集合
- Deployment：提供更新支持
- StatefulSets： 提供有状态支持
- Volume：数据卷
- Labels：标签，资源之间的关联一般通过这个实现

**总结下相关组件**

**Master相关组件**

Master，主控节点，相当于整个集群的大脑。

Master 提供集群的管理控制中心，通常情况下，Master 会独立部署。

**Master 主要组件有：**

- Kube-apiserver

  kube-apiserver 用于暴露 Kubernetes API。任何的资源请求/调用都是通过Kube-apiserver 提供的接口进行。

- Kube-controller-manager

  运行管理控制器，是集群之中用于处理常规任务的后台线程。

- Etcd

  Etcd 是 Kubernetes 提供默认的存储系统，保存所有集群数据。 一般推荐，使用时要使为Etcd 数据提供备份计划。

- scheduler

  是kubernetes 的调度器，主要的任务是把定义的pod分配到集群的节点上。需要考虑资源与效率之间平衡优化的问题。

**Node相关组件**

Node，工作节点，用来从Master 接受任务并执行，并且适当的调整自己的状态或者删除过期的负载。

**Node 的主要组件包括：**

- Kubelet

  Kubelet 是工作节点主要的程序，其会监视已分配给节点的Pod，具体功能包括：

  - 创建Pod 所需的数据卷
  - 创建Pod 所需的网络
  - 下载Pod 所需的Secrets
  - 启动Pod 之中运行的容器
  - 定期执行容器健康检查
  - 上报节点状态

- Kube-proxy

  Kube-proxy 通过主机上维护网络规则并执行连接转发来实现Kubernetes 服务抽象

- Docker/Rkt

  Docker/Rkt 用于运行容器



# 3、Minikube Features

Kubernetes 集群的搭建是有一定难度的，尤其是对于初学者来说，好多概念和原理不懂，即使有现成的教程也会出现很多不可预知的问题，很容易打击学习的积极性，就此弃坑。好在 Kubernetes 社区提供了可以在本地开发和体验的极简集群安装 MiniKube，对于入门学习来说很方便。 Minikube 用于创建单机版的 Kubernetes

- DNS
- NodePorts
- ConfigMaps and Secrets
- Dashboards
- Container Runtime: Docker, CRI-O, and containerd
- Enabling CNI (Container Network Interface)
- Ingress



# 4、Install kubectl

MiniKube 官方安装介绍已经非常详细了，可以参考 installation。但是在国内由于网络访问原因（懂的），即使有梯子也很折腾，所以记录一下阿里修改后的 MiniKube 安装。使用阿里修改后的 MiniKube 就可以从阿里云的镜像地址来获取所需 Docker 镜像和配置，其它的并没有差异，下文着重介绍。

MiniKube 的安装需要先安装 kubectl 及相关驱动，这没什么好说的，参考官方介绍。

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo cp ./kubectl /usr/local/bin/kubectl

sudo kubectl version --client

sudo kubectl --help
```

另 kubectl 也可通过源代码编译安装，编译源码需要有 Git、Golang 环境的支撑。

```bash
➜ git clone https://github.com/kubernetes/kubernetes.git
➜ cd kubernetes
➜ make
➜ sudo cp _output/bin/kubectl /usr/local/bin/
➜ sudo chmod +x /usr/local/bin/kubectl
```

 实现 kubectl 的命令补全功能

```
# make sure bash-completion is installed
sudo apt-get install bash-completion
# make sure bash-completion is sourced in ~/.bashrc (root and other users)
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# or
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
# make sure kubectl completion is sourced in ~/.bashrc (root and other users)
echo 'source <(kubectl completion bash)' >>~/.bashrc
# generate kubectl completion file
sudo bash -c "./kubectl completion bash >/etc/bash_completion.d/kubectl"
```

kubectl 是 Go 语言实现的



# 5、Install a Hypervisor

这是可选项，通过安装 KVM 或 VirtualBox 等工具，Minikube 可以创建 VM 并在上面安装运行程序，如果不安装 Hypervisor 那 Minikube 就在本机上安装运行程序



# 6、Install Minikube

```bash
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

chmod +x minikube

sudo cp ./minikube /usr/local/bin/minikube

sudo minikube start --driver=<driver_name>
```

- 注：minikube带内置的docker, 所以如果不采用--vm-duriver=none可以不用单独安装docker
- vm-driver=none的话是使用本机的docker, 不贴近实际的生产环境，不推荐

上面的镜像源已被墙，可以用国内原源，或者直接下载二进制文件：

> ➜ curl -Lo minikube http://kubernetes.oss-cn-hangzhou.aliyuncs.com/minikube/releases/v0.24.1/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

也可以源码编译安装，编译源码需要有 Git、Golang 环境的支撑。

```bash
➜ git clone https://github.com/AliyunContainerService/minikube
➜ cd minikube
➜ git checkout aliyun-v0.24.1
➜ make
➜ sudo cp out/minikube /usr/local/bin/
➜ sudo chmod +x /usr/local/bin/minikube
```

如果没有安装 Hypervisor，需要将 driver 指定为 none

```
sudo minikube start --driver=none
```

通过 none driver 启动，结果报错

```
😄  Ubuntu 16.04 (vbox/amd64) 上的 minikube v1.11.0
✨  根据用户配置使用 none 驱动程序
💣  Sorry, Kubernetes 1.18.3 requires conntrack to be installed in root's path
```

提示要安装 conntrack

```
sudo apt-get install conntrack
```

重新启动 Minikube

```
😄  Ubuntu 16.04 (vbox/amd64) 上的 minikube v1.11.0
✨  根据用户配置使用 none 驱动程序
👍  Starting control plane node minikube in cluster minikube
🤹  Running on localhost (CPUs=4, Memory=7976MB, Disk=18014MB) ...
ℹ️  OS release is Ubuntu 16.04.6 LTS
🐳  正在 Docker 19.03.8 中准备 Kubernetes v1.18.3…
❗  This bare metal machine is having trouble accessing https://k8s.gcr.io
💡  To pull new external images, you may need to configure a proxy: https://minikube.sigs.k8s.io/docs/reference/networking/proxy/
    > kubeadm.sha256: 65 B / 65 B [--------------------------] 100.00% ? p/s 0s
    > kubectl.sha256: 65 B / 65 B [--------------------------] 100.00% ? p/s 0s
    > kubelet.sha256: 65 B / 65 B [--------------------------] 100.00% ? p/s 0s
    > kubectl: 41.99 MiB / 41.99 MiB [----------------] 100.00% 6.79 MiB p/s 6s
    > kubeadm: 37.97 MiB / 37.97 MiB [----------------] 100.00% 4.44 MiB p/s 9s
    > kubelet: 108.04 MiB / 108.04 MiB [-------------] 100.00% 6.35 MiB p/s 18s

💥  initialization failed, will try again: run: /bin/bash -c "sudo env PATH=/var/lib/minikube/binaries/v1.18.3:$PATH kubeadm init --config /var/tmp/minikube/kubeadm.yaml  --ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests,DirAvailable--var-lib-minikube,DirAvailable--var-lib-minikube-etcd,FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml,FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml,FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml,FileAvailable--etc-kubernetes-manifests-etcd.yaml,Port-10250,Swap": exit status 1
stdout:
[init] Using Kubernetes version: v1.18.3
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'

stderr:
W0609 16:35:49.251770   29943 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
        [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
        [WARNING Swap]: running with swap on is not supported. Please disable swap
        [WARNING FileExisting-ebtables]: ebtables not found in system path
        [WARNING FileExisting-socat]: socat not found in system path
        [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-apiserver:v1.18.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-controller-manager:v1.18.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-scheduler:v1.18.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-proxy:v1.18.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/pause:3.2: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/etcd:3.4.3-0: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/coredns:1.6.7: output: Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
, error: exit status 1
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

还是报错，无法访问 https://k8s.gcr.io，使用国内的源

```
sudo minikube start --driver=none --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

为了访问海外的资源，阿里云提供了一系列基础设施，请按照如下参数进行配置。其中常见参数
--driver=*** 从1.5.0版本开始，Minikube缺省使用本地最好的驱动来创建Kubernetes本地环境，测试过的版本 docker, kvm
--image-mirror-country cn 将缺省利用 registry.cn-hangzhou.aliyuncs.com/google_containers 作为安装Kubernetes的容器镜像仓库 （阿里云版本可选）
--iso-url=*** 利用阿里云的镜像地址下载相应的 .iso 文件 （阿里云版本可选）
--registry-mirror=***为了拉取Docker Hub镜像，需要为 Docker daemon 配置镜像加速，参考阿里云镜像加速服务
--cpus=2: 为minikube虚拟机分配CPU核数
--memory=2048mb: 为minikube虚拟机分配内存数
--kubernetes-version=***: minikube 虚拟机将使用的 kubernetes 版本

成功了

```
😄  Ubuntu 16.04 (vbox/amd64) 上的 minikube v1.11.0
✨  根据现有的配置文件使用 none 驱动程序
👍  Starting control plane node minikube in cluster minikube
🔄  Restarting existing none bare metal machine for "minikube" ...
ℹ️  OS release is Ubuntu 16.04.6 LTS
🐳  正在 Docker 19.03.8 中准备 Kubernetes v1.18.3…
🤹  开始配置本地主机环境...

❗  The 'none' driver is designed for experts who need to integrate with an existing VM
💡  Most users should use the newer 'docker' driver instead, which does not require root!
📘  For more information, see: https://minikube.sigs.k8s.io/docs/reference/drivers/none/

❗  kubectl 和 minikube 配置将存储在 /home/lin 中
❗  如需以您自己的用户身份使用 kubectl 或 minikube 命令，您可能需要重新定位该命令。例如，如需覆盖您的自定义设置，请运行：

    ▪ sudo mv /home/lin/.kube /home/lin/.minikube $HOME
    ▪ sudo chown -R $USER $HOME/.kube $HOME/.minikube

💡  此操作还可通过设置环境变量 CHANGE_MINIKUBE_NONE_USER=true 自动完成
🔎  Verifying Kubernetes components...
🌟  Enabled addons: default-storageclass, storage-provisioner
🏄  完成！kubectl 已经配置至 "minikube"
💡  为获得最佳结果，请安装 kubectl：https://kubernetes.io/docs/tasks/tools/install-kubectl/
```



#  7、minikube on wsl2 

在 wsl2 里运行 minikube 会有更多麻烦事，比如：

```bash
$ sudo apt install conntrack
$ sudo minikube start --driver=none
😄  minikube v1.15.1 on Ubuntu 20.04
✨  Using the none driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🤹  Running on localhost (CPUs=8, Memory=3729MB, Disk=257006MB) ...
ℹ️  OS release is Ubuntu 20.04.1 LTS

❌  Exiting due to RUNTIME_ENABLE: sudo systemctl daemon-reload: exit status 1
stdout:

stderr:
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

这个时候日本有位工程师给出了解决方案：

```bash
$ sudo apt install -yqq daemonize dbus-user-session fontconfig
$ sudo vi /usr/sbin/start-systemd-namespace

#!/bin/bash

SYSTEMD_PID=$(ps -ef | grep '/lib/systemd/systemd --system-unit=basic.target$' | grep -v unshare | awk '{print $2}')
if [ -z "$SYSTEMD_PID" ] || [ "$SYSTEMD_PID" != "1" ]; then
    export PRE_NAMESPACE_PATH="$PATH"
    (set -o posix; set) | \
        grep -v "^BASH" | \
        grep -v "^DIRSTACK=" | \
        grep -v "^EUID=" | \
        grep -v "^GROUPS=" | \
        grep -v "^HOME=" | \
        grep -v "^HOSTNAME=" | \
        grep -v "^HOSTTYPE=" | \
        grep -v "^IFS='.*"$'\n'"'" | \
        grep -v "^LANG=" | \
        grep -v "^LOGNAME=" | \
        grep -v "^MACHTYPE=" | \
        grep -v "^NAME=" | \
        grep -v "^OPTERR=" | \
        grep -v "^OPTIND=" | \
        grep -v "^OSTYPE=" | \
        grep -v "^PIPESTATUS=" | \
        grep -v "^POSIXLY_CORRECT=" | \
        grep -v "^PPID=" | \
        grep -v "^PS1=" | \
        grep -v "^PS4=" | \
        grep -v "^SHELL=" | \
        grep -v "^SHELLOPTS=" | \
        grep -v "^SHLVL=" | \
        grep -v "^SYSTEMD_PID=" | \
        grep -v "^UID=" | \
        grep -v "^USER=" | \
        grep -v "^_=" | \
        cat - > "$HOME/.systemd-env"
    echo "PATH='$PATH'" >> "$HOME/.systemd-env"
    exec sudo /usr/sbin/enter-systemd-namespace "$BASH_EXECUTION_STRING"
fi
if [ -n "$PRE_NAMESPACE_PATH" ]; then
    export PATH="$PRE_NAMESPACE_PATH"
fi
```

然后：

```bash
$ sudo vi /usr/sbin/enter-systemd-namespace

#!/bin/bash

if [ "$UID" != 0 ]; then
    echo "You need to run $0 through sudo"
    exit 1
fi

SYSTEMD_PID="$(ps -ef | grep '/lib/systemd/systemd --system-unit=basic.target$' | grep -v unshare | awk '{print $2}')"
if [ -z "$SYSTEMD_PID" ]; then
    /usr/sbin/daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
    while [ -z "$SYSTEMD_PID" ]; do
        SYSTEMD_PID="$(ps -ef | grep '/lib/systemd/systemd --system-unit=basic.target$' | grep -v unshare | awk '{print $2}')"
    done
fi

if [ -n "$SYSTEMD_PID" ] && [ "$SYSTEMD_PID" != "1" ]; then
    if [ -n "$1" ] && [ "$1" != "bash --login" ] && [ "$1" != "/bin/bash --login" ]; then
        exec /usr/bin/nsenter -t "$SYSTEMD_PID" -a \
            /usr/bin/sudo -H -u "$SUDO_USER" \
            /bin/bash -c 'set -a; source "$HOME/.systemd-env"; set +a; exec bash -c '"$(printf "%q" "$@")"
    else
        exec /usr/bin/nsenter -t "$SYSTEMD_PID" -a \
            /bin/login -p -f "$SUDO_USER" \
            $(/bin/cat "$HOME/.systemd-env" | grep -v "^PATH=")
    fi
    echo "Existential crisis"
fi
```

授权

```bash
$ sudo chmod +x /usr/sbin/enter-systemd-namespace
$ sudo sed -i 2a"# Start or enter a PID namespace in WSL2\nsource /usr/sbin/start-systemd-namespace\n" /etc/bash.bashrc

$ which daemonize
/usr/bin/daemonize

$ sudo sed -i -r 's/\/usr\/sbin\/daemonize/\/usr\/bin\/daemonize/' /usr/sbin/enter-systemd-namespace

# 执行下面这部操作，最好提前开多个窗口，以免文件损坏导致你登录不上去系统
$ exec /bin/bash -l  
You may not change $MAIL
Welcome to Ubuntu 20.04.1 LTS (GNU/Linux 4.19.128-microsoft-standard x86_64)

rm -rf ~/.docker/*

$ sudo minikube start --driver=none
😄  minikube v1.15.1 on Ubuntu 20.04
✨  Using the none driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🤹  Running on localhost (CPUs=8, Memory=3933MB, Disk=257006MB) ...
ℹ️  OS release is Ubuntu 20.04.1 LTS
🐳  Preparing Kubernetes v1.19.4 on Docker 19.03.13 ...
    ▪ kubelet.resolv-conf=/run/systemd/resolve/resolv.conf
🤹  Configuring local host environment ...

❗  The 'none' driver is designed for experts who need to integrate with an existing VM
💡  Most users should use the newer 'docker' driver instead, which does not require root!
📘  For more information, see: https://minikube.sigs.k8s.io/docs/reference/drivers/none/

❗  kubectl and minikube configuration will be stored in /root
❗  To use kubectl or minikube commands as your own user, you may need to relocate them. For example, to overwrite your own settings, run:

    ▪ sudo mv /root/.kube /root/.minikube $HOME
    ▪ sudo chown -R $USER $HOME/.kube $HOME/.minikube

💡  This can also be done automatically by setting the env var CHANGE_MINIKUBE_NONE_USER=true
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
~ $

$ sudo minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured


$ sudo kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.10
deployment.apps/hello-minikube created
$ sudo kubectl expose deployment hello-minikube --type=NodePort --port=8080
service/hello-minikube exposed
$ sudo minikube service hello-minikube --url
http://172.22.141.102:31892
$ curl http://172.22.141.102:31892


Hostname: hello-minikube-5d9b964bfb-q9252

Pod Information:
        -no pod information available-

Server values:
        server_version=nginx: 1.13.3 - lua: 10008

Request Information:
        client_address=172.17.0.1
        method=GET
        real path=/
        query=
        request_version=1.1
        request_scheme=http
        request_uri=http://172.22.141.102:8080/

Request Headers:
        accept=*/*
        host=172.22.141.102:31892
        user-agent=curl/7.68.0

Request Body:
        -no body in request-
```

Minikube 默认至少要双核，如果只有单核，需要指定配置

```
sudo minikube start --driver=none \
                    --extra-config=kubeadm.ignore-preflight-errors=NumCPU \
                    --force --cpus 1 \
                    --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```

检查 Minikube 的状态

```
sudo minikube status
```

正常返回如下

```bash
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

停止集群

```
sudo minikube stop
```

删除集群

```
sudo minikube delete
```

验证 kubectl

```
sudo kubectl version --client
sudo kubectl cluster-info
```

返回

```
lin@lin-VirtualBox:~/K8S$ sudo kubectl version --client
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.3", GitCommit:"2e7996e3e2712684bc73f0dec0200d64eec7fe40", GitTreeState:"clean", BuildDate:"2020-05-20T12:52:00Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
lin@lin-VirtualBox:~/K8S$
lin@lin-VirtualBox:~/K8S$
lin@lin-VirtualBox:~/K8S$ sudo kubectl cluster-info
Kubernetes master is running at https://xxx.xxx.xxx.xxx:8443
KubeDNS is running at https://xxx.xxx.xxx.xxx:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Minikube 是 Go 语言实现的。

最终 wls2 上的正确命令如下：

```bash
sudo minikube start --driver=none \
--image-mirror-country cn \
--iso-url=https://kubernetes.oss-cn-hangzhou.aliyuncs.com/minikube/iso/minikube-v1.15.1.iso  \
--registry-mirror=https://你申请的阿里云镜像加速地址abcdefg.mirror.aliyuncs.com

#下面几条命令未加速，会部署失败
sudo kubectl create deployment hello --image=nginx 
sudo kubectl expose deployment hello --type=NodePort  --port=8888 --target-port=9999 
#sudo kubectl expose deployment hello --type=LoadBalancer   --port=12345
sudo minikube service hello --url
sudo kubectl get svc hello
#sudo kubectl describe svc hello             
sudo kubectl cluster-info
#如果安装了kubeflow，通过以下命令获取Kubeflow Dashboard的访问ip和端口
#export INGRESS_HOST=$(sudo minikube ip)
#export INGRESS_PORT=$(sudo kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}’)


sudo kubectl create deployment hello-minikube \
     --image=registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver:1.10
sudo kubectl expose deployment hello-minikube --type=NodePort --port=8080
sudo minikube service hello-minikube --url
curl -X POST -d '{"abc":123}' http://172.19.82.50:32669/api/v1/hello
```



# 8、例子：echoserver

echoserver 镜像是一个简单的 HTTP 服务器，将请求的 body 携待的参数返回
这里没有定义 manifest 文件，而是直接指定 image 做 deploy，这一步会启动一个 deployment 和对应的 pod

```bash
sudo kubectl create deployment hello-minikube \
     --image=registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver:1.10
```

暴露端口，这一步会启动一个 service

```bash
sudo kubectl expose deployment hello-minikube --type=NodePort --port=8080
```

查看 pod 的状态

```bash
sudo kubectl get pod
sudo kubectl get pods
sudo kubectl get pods -o wide
```

get pod 的返回

```bash
NAME                              READY   STATUS    RESTARTS   AGE
hello-minikube-7df785b6bb-v2phl   1/1     Running   0          5m51s
```

查看 pod 的信息

```bash
sudo kubectl describe pod hello-minikube
```

describe pod 的返回

```bash
Name:         hello-minikube-7df785b6bb-mw6kv
Namespace:    default
Priority:     0
Node:         lin-virtualbox/100.98.137.196
Start Time:   Wed, 10 Jun 2020 16:30:18 +0800
Labels:       app=hello-minikube
              pod-template-hash=7df785b6bb
Annotations:  <none>
Status:       Running
IP:           172.17.0.6
IPs:
  IP:           172.17.0.6
Controlled By:  ReplicaSet/hello-minikube-7df785b6bb
Containers:
  echoserver:
    Container ID:   docker://ca6c7070ef7afc260f6fe6538da49e91bc60ba914b623d6080b03bd2886343b3
    Image:          registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver:1.10
    Image ID:       docker-pullable://registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver@sha256:56bec57144bd3610abd4a1637465ff491dd78a5e2ae523161569fa02cfe679a8
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Wed, 10 Jun 2020 16:30:21 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-znf6q (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-znf6q:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-znf6q
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
```

查看 deployment 的状态

```bash
sudo kubectl get deployment
```

get deployment 的返回

```bash
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
hello-minikube   1/1     1            1           80m
```

查看 service 的状态

```bash
sudo minikube service hello-minikube --url

# or

sudo minikube service hello-minikube
```

返回

```bash
http://100.98.137.196:31526

# or

|-----------|----------------|-------------|-----------------------------|
| NAMESPACE |      NAME      | TARGET PORT |             URL             |
|-----------|----------------|-------------|-----------------------------|
| default   | hello-minikube |        8080 | http://100.98.137.196:31526 |
|-----------|----------------|-------------|-----------------------------|
```

向 echoserver 发送请求

```bash
curl -X POST -d '{"abc":123}' http://100.98.137.196:31526/api/v1/hello
```

返回

```bash
Hostname: hello-minikube-7df785b6bb-v2phl

Pod Information:
        -no pod information available-

Server values:
        server_version=nginx: 1.13.3 - lua: 10008

Request Information:
        client_address=172.17.0.1
        method=POST
        real path=/api/v1/hello
        query=
        request_version=1.1
        request_scheme=http
        request_uri=http://100.98.137.196:8080/api/v1/hello

Request Headers:
        accept=*/*
        content-length=11
        content-type=application/x-www-form-urlencoded
        host=100.98.137.196:31384
        user-agent=curl/7.47.0

Request Body:
{&quot;abc&quot;:123}
```

删除 service

```bash
sudo kubectl delete services hello-minikube
```

删除 service 后 Pod 不受影响还在 running

删除 deployment 后 Pod 才会被删除

```bash
sudo kubectl delete deployment hello-minikube
```

启动 Dashboard

```bash
sudo minikube dashboard
```

返回

```bash
🔌  正在开启 dashboard ...
🤔  正在验证 dashboard 运行情况 ...
🚀  Launching proxy ...
🤔  正在验证 proxy 运行状况 ...

http://127.0.0.1:42155/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

登陆 URL 可以看到

![img](https://cdn.bianchengquan.com/7e7757b1e12abcb736ab9a754ffb617a/blog/6002135a8cf3c.png)
![img](https://cdn.bianchengquan.com/7e7757b1e12abcb736ab9a754ffb617a/blog/6002135a31152.png)
![img](https://cdn.bianchengquan.com/7e7757b1e12abcb736ab9a754ffb617a/blog/60021359b8d76.png)
![img](https://cdn.bianchengquan.com/7e7757b1e12abcb736ab9a754ffb617a/blog/6002135951f8a.png)

命名空间选择 "全部 namespaces"，可以看到，K8S 的组件如 apiserver、controller、etcd、scheduler 等等也是容器化的

实际上这些镜像和启动的容器通过 docker 命令也可以看到

```bash
lin@lin-VirtualBox:~$ docker images
REPOSITORY                                                                    TAG                 IMAGE ID            CREATED             SIZE
registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy                v1.18.3             3439b7546f29        2 weeks ago         117MB
registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler            v1.18.3             76216c34ed0c        2 weeks ago         95.3MB
registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver            v1.18.3             7e28efa976bd        2 weeks ago         173MB
registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager   v1.18.3             da26705ccb4b        2 weeks ago         162MB
kubernetesui/dashboard                                                        v2.0.0              8b32422733b3        7 weeks ago         222MB
registry.cn-hangzhou.aliyuncs.com/google_containers/pause                     3.2                 80d28bedfe5d        3 months ago        683kB
registry.cn-hangzhou.aliyuncs.com/google_containers/coredns                   1.6.7               67da37a9a360        4 months ago        43.8MB
registry.cn-hangzhou.aliyuncs.com/google_containers/etcd                      3.4.3-0             303ce5db0e90        7 months ago        288MB
kubernetesui/metrics-scraper                                                  v1.0.2              3b08661dc379        7 months ago        40.1MB
registry.cn-hangzhou.aliyuncs.com/google_containers/echoserver                1.10                365ec60129c5        2 years ago         95.4MB
registry.cn-hangzhou.aliyuncs.com/google_containers/storage-provisioner       v1.8.1              4689081edb10        2 years ago         80.8MB
docker ps -a
```

可以用 docker 命令操作这些 K8S 启动的容器，比如

```bash
docker exec
docker logs
```

kubectl 也有相应的命令做操作，比如

```bash
kubectl exec
kubectl logs
```

另外绕过 K8S 部署的容器 K8S 无法管理
其它常用命令

```bash
# 查看集群的所有资源
➜ kubectl get all
➜ kubectl get all -o wide

# 进入节点服务器
➜ minikube ssh

# 执行节点服务器命令，例如查看节点 docker info
➜ minikube ssh -- docker info

# 删除集群
➜ minikube delete

# 关闭集群
➜ minikube stop
```



### Wordaround if coredns fail

从 Dashboard 可以看到，有个 coredns 的服务出错了，有的服务会受到影响，比如后面要讲的 Flink on K8S

通过 kubectl get pod 查看状态

```bash
lin@lin-VirtualBox:~/K8S$ sudo kubectl get pod -n kube-system
NAME                                     READY   STATUS             RESTARTS   AGE
coredns-546565776c-5fq7p                 0/1     CrashLoopBackOff   3          7h21m
coredns-546565776c-zx72j                 0/1     CrashLoopBackOff   3          7h21m
etcd-lin-virtualbox                      1/1     Running            0          7h21m
kube-apiserver-lin-virtualbox            1/1     Running            0          7h21m
kube-controller-manager-lin-virtualbox   1/1     Running            0          7h21m
kube-proxy-rgsgg                         1/1     Running            0          7h21m
kube-scheduler-lin-virtualbox            1/1     Running            0          7h21m
storage-provisioner                      1/1     Running            0          7h21m
```

通过 kubectl logs 查看日志

```bash
lin@lin-VirtualBox:~/K8S$ sudo kubectl logs -n kube-system coredns-546565776c-5fq7p
.:53
[INFO] plugin/reload: Running configuration MD5 = 4e235fcc3696966e76816bcd9034ebc7
CoreDNS-1.6.7
linux/amd64, go1.13.6, da7f65b
[FATAL] plugin/loop: Loop (127.0.0.1:58992 -> :53) detected for zone ".", see https://coredns.io/plugins/loop#troubleshooting. Query: "HINFO 5310754532638830744.3332451342029566297."
```

临时方案如下

```bash
# 编辑 coredns 的 ConfigMap，有一行 loop，将其删除 
sudo kubectl edit cm coredns -n kube-system

# 重启服务
sudo kubectl delete pod coredns-546565776c-5fq7p -n kube-system
sudo kubectl delete pod coredns-546565776c-zx72j -n kube-system
```

重启后可以看到 coredns 变成 running 了



# 9、例子：Flink on K8S

定义 manifest 文件
https://ci.apache.org/projects/flink/flink-docs-release-1.10/ops/deployment/kubernetes.html

flink-configuration-configmap.yaml

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: flink-config
  labels:
    app: flink
data:
  flink-conf.yaml: |+
    jobmanager.rpc.address: flink-jobmanager
    taskmanager.numberOfTaskSlots: 1
    blob.server.port: 6124
    jobmanager.rpc.port: 6123
    taskmanager.rpc.port: 6122
    jobmanager.heap.size: 1024m
    taskmanager.memory.process.size: 1024m
  log4j.properties: |+
    log4j.rootLogger=INFO, file
    log4j.logger.akka=INFO
    log4j.logger.org.apache.kafka=INFO
    log4j.logger.org.apache.hadoop=INFO
    log4j.logger.org.apache.zookeeper=INFO
    log4j.appender.file=org.apache.log4j.FileAppender
    log4j.appender.file.file=${log.file}
    log4j.appender.file.layout=org.apache.log4j.PatternLayout
    log4j.appender.file.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
    log4j.logger.org.apache.flink.shaded.akka.org.jboss.netty.channel.DefaultChannelPipeline=ERROR, file
```

jobmanager-deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flink-jobmanager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flink
      component: jobmanager
  template:
    metadata:
      labels:
        app: flink
        component: jobmanager
    spec:
      containers:
      - name: jobmanager
        image: flink:latest
        workingDir: /opt/flink
        command: ["/bin/bash", "-c", "$FLINK_HOME/bin/jobmanager.sh start;\
          while :;
          do
            if [[ -f $(find log -name '*jobmanager*.log' -print -quit) ]];
              then tail -f -n +1 log/*jobmanager*.log;
            fi;
          done"]
        ports:
        - containerPort: 6123
          name: rpc
        - containerPort: 6124
          name: blob
        - containerPort: 8081
          name: ui
        livenessProbe:
          tcpSocket:
            port: 6123
          initialDelaySeconds: 30
          periodSeconds: 60
        volumeMounts:
        - name: flink-config-volume
          mountPath: /opt/flink/conf
        securityContext:
          runAsUser: 9999  # refers to user _flink_ from official flink image, change if necessary
      volumes:
      - name: flink-config-volume
        configMap:
          name: flink-config
          items:
          - key: flink-conf.yaml
            path: flink-conf.yaml
          - key: log4j.properties
            path: log4j.properties
```

taskmanager-deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flink-taskmanager
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flink
      component: taskmanager
  template:
    metadata:
      labels:
        app: flink
        component: taskmanager
    spec:
      containers:
      - name: taskmanager
        image: flink:latest
        workingDir: /opt/flink
        command: ["/bin/bash", "-c", "$FLINK_HOME/bin/taskmanager.sh start; \
          while :;
          do
            if [[ -f $(find log -name '*taskmanager*.log' -print -quit) ]];
              then tail -f -n +1 log/*taskmanager*.log;
            fi;
          done"]
        ports:
        - containerPort: 6122
          name: rpc
        livenessProbe:
          tcpSocket:
            port: 6122
          initialDelaySeconds: 30
          periodSeconds: 60
        volumeMounts:
        - name: flink-config-volume
          mountPath: /opt/flink/conf/
        securityContext:
          runAsUser: 9999  # refers to user _flink_ from official flink image, change if necessary
      volumes:
      - name: flink-config-volume
        configMap:
          name: flink-config
          items:
          - key: flink-conf.yaml
            path: flink-conf.yaml
          - key: log4j.properties
            path: log4j.properties
```

jobmanager-service.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: flink-jobmanager
spec:
  type: ClusterIP
  ports:
  - name: rpc
    port: 6123
  - name: blob
    port: 6124
  - name: ui
    port: 8081
  selector:
    app: flink
    component: jobmanager
```

jobmanager-rest-service.yaml. Optional service, that exposes the jobmanager rest port as public Kubernetes node’s port.

```
apiVersion: v1
kind: Service
metadata:
  name: flink-jobmanager-rest
spec:
  type: NodePort
  ports:
  - name: rest
    port: 8081
    targetPort: 8081
  selector:
    app: flink
    component: jobmanager
```

通过 manifest 文件启动，注意有先后顺序

```
sudo kubectl create -f flink-configuration-configmap.yaml
sudo kubectl create -f jobmanager-service.yaml
sudo kubectl create -f jobmanager-deployment.yaml
sudo kubectl create -f taskmanager-deployment.yaml
```

查看配置的 ConfigMap

```
lin@lin-VirtualBox:~/K8S$ sudo kubectl get configmap
NAME           DATA   AGE
flink-config   2      4h28m
```

查看启动的 Pod

```
lin@lin-VirtualBox:~/K8S$ sudo kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
flink-jobmanager-574676d5d5-g75gh    1/1     Running   0          5m24s
flink-taskmanager-5bdb4857bc-vvn2j   1/1     Running   0          5m23s
flink-taskmanager-5bdb4857bc-wn5c2   1/1     Running   0          5m23s
hello-minikube-7df785b6bb-j9g6g      1/1     Running   0          55m
```

查看启动的 Deployment

```
lin@lin-VirtualBox:~/K8S$ sudo kubectl get deployment
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
flink-jobmanager    1/1     1            1           4h28m
flink-taskmanager   1/2     2            1           4h28m
hello-minikube      1/1     1            1           5h18m
```

查看启动的 Service

```
lin@lin-VirtualBox:~/K8S$ sudo kubectl get service
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
flink-jobmanager   ClusterIP   10.96.132.16     <none>        6123/TCP,6124/TCP,8081/TCP   4h28m
hello-minikube     NodePort    10.104.137.240   <none>        8080:30041/TCP               5h18m
kubernetes         ClusterIP   10.96.0.1        <none>        443/TCP                      5h25m
```

登陆 Flink UI 以及提交 Flink Job 的几种方式
https://ci.apache.org/projects/flink/flink-docs-release-1.10/ops/deployment/kubernetes.html#deploy-flink-session-cluster-on-kubernetes

（1）proxy 方式

命令

```bash
kubectl proxy
```

登陆 URL

```bash
http://localhost:8001/api/v1/namespaces/default/services/flink-jobmanager:ui/proxy
```

（这种方式没讲到怎么 run job）

（2）NodePort service 方式

命令

```bash
sudo kubectl create -f jobmanager-rest-service.yaml
sudo kubectl get svc flink-jobmanager-rest
lin@lin-VirtualBox:~/K8S$ sudo kubectl get svc flink-jobmanager-rest
NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
flink-jobmanager-rest   NodePort   10.96.150.145   <none>        8081:32598/TCP   12s
```

登陆 URL

```bash
http://10.96.150.145:8081
```

提交 Job

```bash
./bin/flink run -m 10.96.150.145:8081 ./examples/streaming/WordCount.jar
```

在 UI 上可以看到提交的 Job

（3）port-forward （kubectl port-forward 的工作原理 ： 使用了 socat 和 nsenter 完成其工作 ）

宿主机安装 socat

```
sudo apt-get install socat
```

命令

```
sudo kubectl port-forward flink-jobmanager-574676d5d5-xd9kx 8081:8081
```

登陆 URL

```bash
http://localhost:8081
```

提交 Job

```bash
./bin/flink run -m localhost:8081 ./examples/streaming/WordCount.jar
```

在 UI 上可以看到提交的 Job
删除 Flink

```bash
sudo kubectl delete -f jobmanager-deployment.yaml
sudo kubectl delete -f taskmanager-deployment.yaml
sudo kubectl delete -f jobmanager-service.yaml
sudo kubectl delete -f flink-configuration-configmap.yaml
```



# Refer：

[0] Kubernetes：通过 minikube 安装单机测试环境

https://www.cnblogs.com/moonlight-lin/p/13128702.html

[1] WSL2とkubernetes - 0から学ぶkubernetes day02

https://qiita.com/kotazuck/items/cc3ff8f0844075cf20e4

[2] Spark on K8S （Kubernetes Native）

https://www.cnblogs.com/moonlight-lin/p/13296909.html

[3] Docker 安装和使用

https://www.cnblogs.com/moonlight-lin/p/12832578.html

[4] Docker 和 Kubernetes：给程序员的快速指南

https://zhuanlan.zhihu.com/p/39937913

[5] 使用 Minikube 安装 Kubernetes

https://v1-18.docs.kubernetes.io/zh/docs/setup/learning-environment/minikube/

[6] 使用 kubectl 创建 Deployment

https://kubernetes.io/zh/docs/tutorials/kubernetes-basics/deploy-app/deploy-intro/
