---
title: Kube Prometheus 新增监控项
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-04-20 18:06:13
tags:
---

## 概述

Kube Prometheus 是官方基于prometheus-operator项目做的定制版，prometheus-operator通过k8s CRD做了定制和扩展，相较于官方的基本Prometheus项目，可用提供更便捷的管理和控制。

我们当前就是采用Kube Prometheus做kubernetes监控。

基本Prometheus添加监控配置是比较复杂的，我们需要写下面这样的job\_name，需要去了解各个字段的配置含义，而且原始项目不支持配置热更新，需要我们自己监听ConfigMap的变更重启服务生效配置。

```
- job_name: 'node_exporter'
  scrape_interval: 1s
  file_sd_configs:
    - files:
      - targets/node/*.yml
      refresh_interval: 10s
  relabel_configs:
  - action: replace
    source_labels: ['__address__']
    regex: (.*):(.*)
    replacement: $1
    target_label: hostname
  - action: labeldrop
    regex: __meta_filepath
```

使用Kube Prometheus之后，这一切就变的很简单了，CRD的声明是`prometheus-operator-0servicemonitorCustomResourceDefinition.yaml`这个文件

```
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  creationTimestamp: null
  name: servicemonitors.monitoring.coreos.com
spec:
  group: monitoring.coreos.com
  names:
    kind: ServiceMonitor
    plural: servicemonitors
  scope: Namespaced
```

我们只需要创建一个ServiceMonitor类型的资源对象，再做一些配置即可。下面我们通过一个实例来总结一下Kube Prometheus怎么新增监控项

## 总结

先上总结：

-   总体来说，需要提供一个service，去访问采集服务地址，让Prometheus能拉取到数据
-   之后要声明一个ServiceMonitor类型的资源对象，让Kube Prometheus监听到有新的监控项
-   特别要注意的是，如果是跨集群访问，需要提供对应的rbac资源对象。因为Kube Prometheus默认是部署在monitoring中的，一般其它服务也不会在这个命名空间中
-   虽然Kube Prometheus提供热加载和自动发现更新配置的机制，但是也有一定的学习的踩坑成本，第一次实践多少会遇到一些问题，可用多参考官方文档和CRD中定义的字段

下面我们演示跨命名空间的监控配置

## 配置

首先要创建rbac资源对象，为了让Prometheus能跨命名空间拉取采集服务的指标

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus-k8s-paas
  namespace: eos-system
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - pods
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus-k8s-paas
  namespace: eos-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s-paas
subjects:
  - kind: ServiceAccount
    name: prometheus-k8s  # prometheus-k8s已经在 kube-prometheus中创建过
    namespace: monitoring
```

假设我们的采集服务的Jenkins，暴露的端口是8080，我们可以配置一个service，重点在与对这个service注入两个annotations

```
apiVersion: v1
kind: Service
metadata:
  name: jenkins-monitor-service
  namespace: eos-system
  annotations:
    prometheus.io/port: "2333"  # 声明端口
    prometheus.io/scrape: "true" # 声明scrape 为 true
  labels: 
    app: jenkins-monitor-service
spec:
  ports:
  - protocol: TCP
    targetPort: 8080
    port: 2333
    name: metrics
  selector:
    app: eos-jenkins
```

以上两个annotations是约定值，具体可用参考官方文档的说明 [https://github.com/prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator)

[![image](https://www.liuzhidream.com/images/monitor/monitor2.png)](https://www.liuzhidream.com/images/monitor/monitor2.png "image")

[image](https://www.liuzhidream.com/images/monitor/monitor2.png "image")

最后，我们还需要定义一个ServiceMonitor

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: jenkins-monitoring
  namespace: monitoring
spec:
  endpoints:
  - interval: 15s
    port: metrics
    path: "/prometheus/"
  namespaceSelector:
    matchNames:
    - eos-system
  selector:
    matchLabels:
      app: jenkins-monitor-service
```

把资源对象都运用，等一会儿后，可以去prometheus的Ui界面查看新增监控项是否可用

[![image](https://www.liuzhidream.com/images/monitor/monitor1.png)](https://www.liuzhidream.com/images/monitor/monitor1.png "image")

[image](https://www.liuzhidream.com/images/monitor/monitor1.png "image")

ok，我们发现新增的ServiceMonitor类型的资源对象jenkins-monitoring已经被Prometheus找到了，并且state是up，代表采集数据正常。之后可用结合grafana做看板

## 扩展-实现机制

有了CRD，就可以自己写一个控制器，去监听对应资源对象，比如ServiceMonitor的状态，利用kubernete的watch机制，

具体可以参考官方文档 [https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/troubleshooting.md](https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/troubleshooting.md)

## 参考

[https://www.cnblogs.com/eastpig/p/13256510.html](https://www.cnblogs.com/eastpig/p/13256510.html)
