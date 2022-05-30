---
title: 使用kube-prometheus部署k8s监控(最新版)
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-27 11:12:46
tags:
---

> `kubernetes`的最新版本已经到了`1.20.x`，利用假期时间搭建了最新的`k8s v1.20.2`版本，截止我整理此文为止，发现官方最新的`release`已经更新到了`v1.20.4`。

## 1、概述

### 1.1 在k8s中部署Prometheus监控的方法

通常在`k8s`中部署`prometheus`监控可以采取的方法有以下三种

- 通过yaml手动部署
- operator部署
- 通过helm chart部署

### 1.2 什么是Prometheus Operator

`Prometheus Operator`的本职就是一组用户自定义的`CRD`资源以及`Controller`的实现，`Prometheus Operator`负责监听这些自定义资源的变化，并且根据这些资源的定义自动化的完成如`Prometheus Server`自身以及配置的自动化管理工作。以下是`Prometheus Operator`的架构图

![img](https://image.ssgeek.com/20210226-01.png)

图片来源：

https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/Documentation/user-guides/images/architecture.png

### 1.3 为什么用Prometheus Operator

由于`Prometheus`本身没有提供管理配置的`AP`接口（尤其是管理监控目标和管理警报规则），也没有提供好用的多实例管理手段，因此这一块往往要自己写一些代码或脚本。为了简化这类应用程序的管理复杂度，`CoreOS`率先引入了`Operator`的概念，并且首先推出了针对在`Kubernetes`下运行和管理`Etcd`的`Etcd Operator`。并随后推出了`Prometheus Operator`

### 1.4 kube-prometheus项目介绍

prometheus-operator官方地址：https://github.com/prometheus-operator/prometheus-operator
kube-prometheus官方地址：https://github.com/prometheus-operator/kube-prometheus

两个项目的关系：前者只包含了`Prometheus Operator`，后者既包含了`Operator`，又包含了`Prometheus`相关组件的部署及常用的`Prometheus`自定义监控，具体包含下面的组件

- The Prometheus Operator：创建CRD自定义的资源对象
- Highly available Prometheus：创建高可用的Prometheus
- Highly available Alertmanager：创建高可用的告警组件
- Prometheus node-exporter：创建主机的监控组件
- Prometheus Adapter for Kubernetes Metrics APIs：创建自定义监控的指标工具（例如可以通过nginx的request来进行应用的自动伸缩）
- kube-state-metrics：监控k8s相关资源对象的状态指标
- Grafana：进行图像展示

## 2、环境介绍

本文的`k8s`环境是通过`kubeadm`搭建的`v 1.20.2`版本，由1`master`+2`node`组合

持久化存储为`storageclass`动态存储，底层由`ceph-rbd`提供

```yaml
➜  kubectl version -o yaml
clientVersion:
  buildDate: "2020-12-08T17:59:43Z"
  compiler: gc
  gitCommit: af46c47ce925f4c4ad5cc8d1fca46c7b77d13b38
  gitTreeState: clean
  gitVersion: v1.20.0
  goVersion: go1.15.5
  major: "1"
  minor: "20"
  platform: darwin/amd64
serverVersion:
  buildDate: "2021-01-13T13:20:00Z"
  compiler: gc
  gitCommit: faecb196815e248d3ecfb03c680a4507229c2a56
  gitTreeState: clean
  gitVersion: v1.20.2
  goVersion: go1.15.5
  major: "1"
  minor: "20"
  platform: linux/amd64
➜  kubectl get nodes                                     
NAME       STATUS   ROLES                  AGE   VERSION
k8s-m-01   Ready    control-plane,master   11d    v1.20.2
k8s-n-01   Ready    <none>                 11d    v1.20.2
k8s-n-02   Ready    <none>                 11d    v1.20.2
➜  manifests kubectl get sc                                              
NAME                            PROVISIONER                                   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
dynamic-ceph-rbd (default)      ceph.com/rbd                                  Delete          Immediate           false                  7d23h
```

`kube-prometheus`的兼容性说明（https://github.com/prometheus-operator/kube-prometheus#kubernetes-compatibility-matrix），按照兼容性说明，部署的是最新的`release-0.7`版本

| kube-prometheus stack | Kubernetes 1.16 | Kubernetes 1.17 | Kubernetes 1.18 | Kubernetes 1.19 | Kubernetes 1.20 |
| --------------------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| `release-0.4`         | ✔ (v1.16.5+)    | ✔               | ✗               | ✗               | ✗               |
| `release-0.5`         | ✗               | ✗               | ✔               | ✗               | ✗               |
| `release-0.6`         | ✗               | ✗               | ✔               | ✔               | ✗               |
| `release-0.7`         | ✗               | ✗               | ✗               | ✔               | ✔               |
| `HEAD`                | ✗               | ✗               | ✗               | ✔               | ✔               |

## 3、清单准备

从官方的地址获取最新的`release-0.7`分支，或者直接打包下载`release-0.7`

```shell
➜  git clone https://github.com/prometheus-operator/kube-prometheus.git
➜  git checkout release-0.7
或者
➜  wget -c https://github.com/prometheus-operator/kube-prometheus/archive/v0.7.0.zip
```

默认下载下来的文件较多，建议把文件进行归类处理，将相关`yaml`文件移动到对应目录下

```shell
➜  cd kube-prometheus/manifests
➜  mkdir -p serviceMonitor prometheus adapter node-exporter kube-state-metrics grafana alertmanager operator other
```

最终结构如下

```shell
➜  manifests tree .
.
├── adapter
│   ├── prometheus-adapter-apiService.yaml
│   ├── prometheus-adapter-clusterRole.yaml
│   ├── prometheus-adapter-clusterRoleAggregatedMetricsReader.yaml
│   ├── prometheus-adapter-clusterRoleBinding.yaml
│   ├── prometheus-adapter-clusterRoleBindingDelegator.yaml
│   ├── prometheus-adapter-clusterRoleServerResources.yaml
│   ├── prometheus-adapter-configMap.yaml
│   ├── prometheus-adapter-deployment.yaml
│   ├── prometheus-adapter-roleBindingAuthReader.yaml
│   ├── prometheus-adapter-service.yaml
│   └── prometheus-adapter-serviceAccount.yaml
├── alertmanager
│   ├── alertmanager-alertmanager.yaml
│   ├── alertmanager-secret.yaml
│   ├── alertmanager-service.yaml
│   └── alertmanager-serviceAccount.yaml
├── grafana
│   ├── grafana-dashboardDatasources.yaml
│   ├── grafana-dashboardDefinitions.yaml
│   ├── grafana-dashboardSources.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-service.yaml
│   └── grafana-serviceAccount.yaml
├── kube-state-metrics
│   ├── kube-state-metrics-clusterRole.yaml
│   ├── kube-state-metrics-clusterRoleBinding.yaml
│   ├── kube-state-metrics-deployment.yaml
│   ├── kube-state-metrics-service.yaml
│   └── kube-state-metrics-serviceAccount.yaml
├── node-exporter
│   ├── node-exporter-clusterRole.yaml
│   ├── node-exporter-clusterRoleBinding.yaml
│   ├── node-exporter-daemonset.yaml
│   ├── node-exporter-service.yaml
│   └── node-exporter-serviceAccount.yaml
├── operator
│   ├── 0namespace-namespace.yaml
│   ├── prometheus-operator-0alertmanagerConfigCustomResourceDefinition.yaml
│   ├── prometheus-operator-0alertmanagerCustomResourceDefinition.yaml
│   ├── prometheus-operator-0podmonitorCustomResourceDefinition.yaml
│   ├── prometheus-operator-0probeCustomResourceDefinition.yaml
│   ├── prometheus-operator-0prometheusCustomResourceDefinition.yaml
│   ├── prometheus-operator-0prometheusruleCustomResourceDefinition.yaml
│   ├── prometheus-operator-0servicemonitorCustomResourceDefinition.yaml
│   ├── prometheus-operator-0thanosrulerCustomResourceDefinition.yaml
│   ├── prometheus-operator-clusterRole.yaml
│   ├── prometheus-operator-clusterRoleBinding.yaml
│   ├── prometheus-operator-deployment.yaml
│   ├── prometheus-operator-service.yaml
│   └── prometheus-operator-serviceAccount.yaml
├── other
├── prometheus
│   ├── prometheus-clusterRole.yaml
│   ├── prometheus-clusterRoleBinding.yaml
│   ├── prometheus-prometheus.yaml
│   ├── prometheus-roleBindingConfig.yaml
│   ├── prometheus-roleBindingSpecificNamespaces.yaml
│   ├── prometheus-roleConfig.yaml
│   ├── prometheus-roleSpecificNamespaces.yaml
│   ├── prometheus-rules.yaml
│   ├── prometheus-service.yaml
│   └── prometheus-serviceAccount.yaml
└── serviceMonitor
    ├── alertmanager-serviceMonitor.yaml
    ├── grafana-serviceMonitor.yaml
    ├── kube-state-metrics-serviceMonitor.yaml
    ├── node-exporter-serviceMonitor.yaml
    ├── prometheus-adapter-serviceMonitor.yaml
    ├── prometheus-operator-serviceMonitor.yaml
    ├── prometheus-serviceMonitor.yaml
    ├── prometheus-serviceMonitorApiserver.yaml
    ├── prometheus-serviceMonitorCoreDNS.yaml
    ├── prometheus-serviceMonitorKubeControllerManager.yaml
    ├── prometheus-serviceMonitorKubeScheduler.yaml
    └── prometheus-serviceMonitorKubelet.yaml

9 directories, 67 files
```

修改yaml，增加prometheus和grafana的持久化存储

manifests/prometheus/prometheus-prometheus.yaml

```yaml
...
  serviceMonitorSelector: {}
  version: v2.22.1
  retention: 3d
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: dynamic-ceph-rbd
        resources:
          requests:
            storage: 5Gi
```

manifests/grafana/grafana-deployment.yaml

```yaml
...
      serviceAccountName: grafana
      volumes:
#      - emptyDir: {}
#        name: grafana-storage
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-data
```

新增grafana的pvc，manifests/other/grafana-pvc.yaml

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: grafana-data
  namespace: monitoring
  annotations:
    volume.beta.kubernetes.io/storage-class: "dynamic-ceph-rbd"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
```

## 4、开始部署

部署清单

```shell
➜  kubectl create -f other/grafana-pvc.yaml 
➜  kubectl create -f operator/
➜  kubectl create -f adapter/ -f alertmanager/ -f grafana/ -f kube-state-metrics/ -f node-exporter/ -f prometheus/ -f serviceMonitor/ 
```

查看状态

```shell
➜  kubectl get po,svc -n monitoring 
NAME                                       READY   STATUS    RESTARTS   AGE
pod/alertmanager-main-0                    2/2     Running   0          15m
pod/alertmanager-main-1                    2/2     Running   0          10m
pod/alertmanager-main-2                    2/2     Running   0          15m
pod/grafana-d69dcf947-wnspk                1/1     Running   0          22m
pod/kube-state-metrics-587bfd4f97-bffqv    3/3     Running   0          22m
pod/node-exporter-2vvhv                    2/2     Running   0          22m
pod/node-exporter-7nsz5                    2/2     Running   0          22m
pod/node-exporter-wggpp                    2/2     Running   0          22m
pod/prometheus-adapter-69b8496df6-cjw6w    1/1     Running   0          23m
pod/prometheus-k8s-0                       2/2     Running   1          75s
pod/prometheus-k8s-1                       2/2     Running   0          9m33s
pod/prometheus-operator-7649c7454f-nhl72   2/2     Running   0          28m

NAME                            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
service/alertmanager-main       ClusterIP   10.1.189.238   <none>        9093/TCP                     23m
service/alertmanager-operated   ClusterIP   None           <none>        9093/TCP,9094/TCP,9094/UDP   23m
service/grafana                 ClusterIP   10.1.29.30     <none>        3000/TCP                     23m
service/kube-state-metrics      ClusterIP   None           <none>        8443/TCP,9443/TCP            23m
service/node-exporter           ClusterIP   None           <none>        9100/TCP                     23m
service/prometheus-adapter      ClusterIP   10.1.75.64     <none>        443/TCP                      23m
service/prometheus-k8s          ClusterIP   10.1.111.121   <none>        9090/TCP                     23m
service/prometheus-operated     ClusterIP   None           <none>        9090/TCP                     14m
service/prometheus-operator     ClusterIP   None           <none>        8443/TCP                     28m
```

为`prometheus`、`grafana`、`alertmanager`创建`ingress`

manifests/other/ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prom-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
    prometheus.io/http_probe: "true"
spec:
  rules:
  - host: alert.k8s-1.20.2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager-main
            port:
              number: 9093
  - host: grafana.k8s-1.20.2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
  - host: prom.k8s-1.20.2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-k8s
            port:
              number: 9090
```

## 5、解决ControllerManager、Scheduler监控问题

默认安装后访问`prometheus`，会发现有以下有三个报警：

```
Watchdog`、`KubeControllerManagerDown`、`KubeSchedulerDown
```

`Watchdog`是一个正常的报警，这个告警的作用是：如果`alermanger`或者`prometheus`本身挂掉了就发不出告警了，因此一般会采用另一个监控来监控`prometheus`，或者自定义一个持续不断的告警通知，哪一天这个告警通知不发了，说明监控出现问题了。`prometheus operator`已经考虑了这一点，本身携带一个`watchdog`，作为对自身的监控。

如果需要关闭，删除或注释掉`Watchdog`部分

prometheus-rules.yaml

```shell
...
  - name: general.rules
    rules:
    - alert: TargetDown
      annotations:
        message: 'xxx'
      expr: 100 * (count(up == 0) BY (job, namespace, service) / count(up) BY (job, namespace, service)) > 10
      for: 10m
      labels:
        severity: warning
#    - alert: Watchdog
#      annotations:
#        message: |
#          This is an alert meant to ensure that the entire alerting pipeline is functional.
#          This alert is always firing, therefore it should always be firing in Alertmanager
#          and always fire against a receiver. There are integrations with various notification
#          mechanisms that send a notification when this alert is not firing. For example the
#          "DeadMansSnitch" integration in PagerDuty.
#      expr: vector(1)
#      labels:
#        severity: none
```

`KubeControllerManagerDown`、`KubeSchedulerDown`的解决

原因是因为在prometheus-serviceMonitorKubeControllerManager.yaml中有如下内容，但默认安装的集群并没有给系统`kube-controller-manager`组件创建`svc`

```yaml
  selector:
    matchLabels:
      k8s-app: kube-controller-manager
```

修改`kube-controller-manager`的监听地址

```shell
# vim /etc/kubernetes/manifests/kube-controller-manager.yaml
...
spec:
  containers:
  - command:
    - kube-controller-manager
    - --allocate-node-cidrs=true
    - --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf
    - --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf
    - --bind-address=0.0.0.0
# netstat -lntup|grep kube-contro                                      
tcp6       0      0 :::10257                :::*                    LISTEN      38818/kube-controll
```

创建一个`service`和`endpoint`，以便`serviceMonitor`监听

other/kube-controller-namager-svc-ep.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-controller-manager
  namespace: kube-system
  labels:
    k8s-app: kube-controller-manager
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - name: https-metrics
    port: 10257
    targetPort: 10257
    protocol: TCP

---
apiVersion: v1
kind: Endpoints
metadata:
  name: kube-controller-manager
  namespace: kube-system
  labels:
    k8s-app: kube-controller-manager
subsets:
- addresses:
  - ip: 172.16.1.71
  ports:
    - name: https-metrics
      port: 10257
      protocol: TCP
```

`kube-scheduler`同理，修改`kube-scheduler`的监听地址

```shell
# vim /etc/kubernetes/manifests/kube-scheduler.yaml
...
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=0.0.0.0
# netstat -lntup|grep kube-sched
tcp6       0      0 :::10259                :::*                    LISTEN      100095/kube-schedul
```

创建一个`service`和`endpoint`，以便`serviceMonitor`监听

kube-scheduler-svc-ep.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-scheduler
  namespace: kube-system
  labels:
    k8s-app: kube-scheduler
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - name: https-metrics
    port: 10259
    targetPort: 10259
    protocol: TCP

---
apiVersion: v1
kind: Endpoints
metadata:
  name: kube-scheduler
  namespace: kube-system
  labels:
    k8s-app: kube-scheduler
subsets:
- addresses:
  - ip: 172.16.1.71
  ports:
    - name: https-metrics
      port: 10259
      protocol: TCP
```

再次查看`prometheus`的`alert`界面，全部恢复正常

![img](https://image.ssgeek.com/20210226-02.png)

登录到`grafana`，查看相关图像展示

![img](https://image.ssgeek.com/20210226-03.png)

至此，通过`kube-prometheus`部署`k8s`监控已经基本完成了，后面再分享自定义监控和告警、告警通知、高可用、规模化部署等相关内容

> 参考：https://github.com/prometheus-operator/kube-prometheus
