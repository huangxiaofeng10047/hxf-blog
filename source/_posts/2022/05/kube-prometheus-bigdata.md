---
title: kube-prometheus-bigdata
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-27 10:23:36
tags:
---

本文介绍了如何基于kube-prometheus设计一个监控系统， 以灵活简单的方式对kubernetes上的应用进行指标采集，并实现监控报警功能。
本文提供了作者的应用示例，另外还记录了作者在学习、使用Prometheus过程中的一些笔记，如arm版镜像获取、一些工具的使用等。

## 零 前言

众所周知，大数据产品作为底层平台，其运维监控一直是生产实践的痛点难点，且在稳定运行的基础之上
往往还需要对性能进行评估优化，所以其监控系统的建设显得尤为重要。

Prometheus作为云原生时代最火的监控软件，很多大数据组件或原生或以第三方插件/exporter的形式对Prometheus做了支持。

我使用的大数据平台是基于kubernetes运行的，有部署灵活管理方便的优点，更容易与Prometheus进行结合。

下面将对设计思路和技术实现进行阐述探讨。

## 一 设计思路

监控系统的核心任务是将暴露出来的指标数据进行抓取，在此之上进行分析、告警
所以有以下几个要明确的问题：

1. 监控对象是什么
2. 监控对象如何暴露指标数据
3. 监控系统如何对指标进行抓取
4. 如何实现告警规则动态配置、管理

### 1. 监控对象

以pod（容器）形式运行在kubernetes集群上的各个大数据组件。

### 2. 指标暴露方式

各组件根据对Prometheus的支持程度，可分为3种类型的指标暴露方式：

1. 直接暴露Prometheus指标数据(直接，拉)
2. 主动将指标数据推送到prometheus-pushGateway，由pushGateway暴露数据（间接，推）
3. 自定义exporter将其他形式的指标数据转换为符合Prometheus标准的格式进行暴露（exporter，直接，拉）

个别组件同时支持多种方式，如flink支持直接和间接方式，spark支持直接方式而且也有第三方exporter。
大部分组件都有官方/第三方的exporter，极少数需要自己开发。

一般情况下直接方式就可以了
需要注意的是，像flink（spark） on yarn模式运行的时候，flink节点是跑在yarn容器里面的。
这种情况下Prometheus很难对其直接进行抓取，这种时候就只能用间接方式，主动将数据推送到pushGateway。

另外那些短暂生命周期的组件也建议用主动push到pushGateway。

### 3. 指标抓取方式

不管是exporter还是pushGateway，到最后必然是由Prometheus主动对这些目标进行抓取。

> Prometheus 主要通过 Pull 的方式来抓取目标服务暴露出来的监控接口，
> 因此需要配置对应的抓取任务来请求监控数据并写入到 Prometheus 提供的存储中，
> 目前 Prometheus 服务提供了如下几个任务的配置：
>
> - 原生 Job 配置：提供 Prometheus 原生抓取 Job 的配置。
> - Pod Monitor：在 K8S 生态下，基于 Prometheus Operator 来抓取 Pod 上对应的监控数据。
> - Service Monitor：在 K8S 生态下，基于 Prometheus Operator 来抓取 Service 对应 Endpoints 上的监控数据。
>
> 参考：https://cloud.tencent.com/document/product/1416/55995

既然都上了kubernetes环境了，一般当然是推荐直接用 podMonitor。配置更简洁易懂。
podMonitorSelector的过滤在prometheus-prometheus.yaml配置。

> prometheus-prometheus.yaml是核心配置文件，不宜频繁修改(会导致Prometheus重启)。
> 主要配置项为：serviceMonitorSelector，podMonitorSelector，ruleSelector，alertmanagers。
> 其中service监控选择器和pod监控选择器默认选择所有，这里建议把 ruleSelector 也修改为选择所有

不过一个podMonitor一般只对应一种类型的pod，在已有pod类型较多的情况下，
还可以考虑一种更取巧的方法就是Prometheus的kubernetes服务发现功能。即kubernetes_sd_config。
这种属于*原生Job配置*，建议使用[additional-scrape-config](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/additional-scrape-config.md)
进行配置。

[kubernetes_sd_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)赋予了Prometheus通过kubernetes rest api感知kubernetes资源的功能，
利用该能力，可以使用*原生Job配置*自动发现pod，将其作为监控目标。
再利用Prometheus的[Relabel功能](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config)可以改写发现的标签，进行前置处理、转换。实现pod筛选，修改抓取配置的效果。
而自动发现的pod的标签的来源又可以是pod资源的label/annotation等。
最终实现的效果如下，
这是一个pushGateway的pod的配置,则Prometheus会通过其19091端口访问/metrics路径获取其指标数据

```yaml
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/scheme: "http"
    prometheus.io/path: "/metrics"
    prometheus.io/port: "19091"
```

这部分的内容主要参考：

1. https://godleon.github.io/blog/Prometheus/Prometheus-Relabel
2. https://yunlzheng.gitbook.io/prometheus-book/part-iii-prometheus-shi-zhan/readmd/service-discovery-with-kubernetes

podMonitor是官方支持，简洁易懂。
kubernetes_sd_config+relabel的方案较复杂，难度较高，但不用写那么多的podMonitor。
自行抉择就行，也可以一起用。

### 4. 告警设计

#### 告警流程

prometheus的监控告警基本流程是：

1. 服务发生异常
2. 触发prometheus服务器发出告警信息（alert）
3. alertmanager收到告警信息
4. alertmanager根据预配置的规则对告警信息进行处理，实现业务逻辑，如分组、抑制、触发短信邮箱等

当然具体的流程没那么简单，有很多细节需要注意，特别是触发告警时机，是个重点。
这些属于Prometheus的机制实现，这里就不展开赘述，推荐阅读以下文章：
[Prometheus 一条告警的触发流程、等待时间](https://my.oschina.net/u/4400455/blog/3442101)
[AlertManager 何时报警](https://www.qikqiak.com/post/alertmanager-when-alert/)

后边会给出一个本人实际应用测试的例子，可供参考，会直观一些。

#### 告警的动态配置

kube-prometheus的告警规则分两部分：

1. alertmanager: 即对告警信息的处理策略
   配置参考：https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/alert-manager-config
   核心是alertmanager-secret.yaml配置文件，该文件以 secret 的形式被 Alertmanager 读取。
   Alertmanager会自动读取secret中的配置进行更新。
2. alertRule: 即具体的告警规则
   配置参考：https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/prometheus-alert-rule
   在kubernetes中是以PrometheusRule类型操作，所以管理起来跟pod一样，直接使用kubelet增删改即可

#### 接入自定义告警平台

从个人实践的角度来看，AlertManager处理web hook之外的告警接收插件，如短信、邮箱等只适合测着玩。
生产使用还是要通过web hook将告警信息发送到自己的告警平台。可以根据业务需要对告警信息做高度定制化处理、记录等。
另外可以在告警信息中携带具体告警规则等信息指导告警平台进行处理。

这里要做个区分，AlertManager是告警信息的前置处理，负责非业务性前置操作，如告警信息分组、平抑等。
而自定义告警平台则负责告警信息的业务处理，如记录、去敏、发送到多终端等。

AlertManager可能收到1w条告警信息，经过处理最终只发了1条到自定义告警平台。
而自定义告警平台可以将这1条告警信息记录起来，修改内容，同时使用邮箱、短信通知到多个负责人。

#### 告警层级标签设计

监控对象的粒度决定告警的层级，体现在配置上则是告警规则的分组。
分组信息决定alertManager的处理方式。
alertManager对告警信息的路由策略是树状的，所以可通过多个分组标签实现多层级路由处理。
具体设计应结合业务需求，不在这里展开，感兴趣的可以看我下面的实现举例。

## 二 技术实现

技术实现主要分以下几部分：

1. kubernetes环境下prometheus的部署(kube-prometheus)
2. kube-prometheus的增强配置:即kubernetes_sd_config+relabel方案的实现
3. bigdata-exporter的实现
4. 告警设计实例

### 1. kubernetes环境下prometheus的部署

#### 1) kube-prometheus vs prometheus-operator

github 上 coreos 下有两个项目： kube-prometheus 和 prometheus-operator，
两者都可以实现 prometheus 的创建及管理。

需要注意的是，kube-prometheus 上的配置操作也是基于 prometheus-operator 的，
并提供了大量的默认配置，故这里使用的是 kube-prometheus 项目的配置。

另外使用前需注意k8s版本要求，找到对应的kube-prometheus版本，弄清楚对应的prometheus-operator版本
如：k8s1.14版本最高可使用 kube-prometheus 0.3，对应的 prometheus-operator 版本是 0.32
阅读文档时注意对应版本。

#### 2) kube-prometheus 使用前说明

kube-prometheus 使用 jsonnet 编写配置模板文件，生成k8s配置清单
已提供默认清单文件，在 manifests 文件夹下
如果需要修改默认清单配置，需要在go环境下使用jp编译清单
下面都以默认配置为例

#### 3) 安装教程

参考官方说明即可

1. git clone 项目 并切换到指定分支

2. kubectl create

   清单文件中各配置已附带namespace信息，故执行时不需要指定namespace，否则可能出错。

   官方命令如下：

   ```shell
   #Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
    
   kubectl create -f manifests/setup
   until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
   kubectl create -f manifests/
   ```

### 2. kubernetes_sd_config+relabel方案的实现

见： https://github.com/linshenkx/kube-prometheus-enhance

### 3. bigdata-exporter的实现

hdfs、yarn、hbase、yarn等组件都提供了web获取jmx指标的方式。

这里的思路是使用一个bigdata-exporter，去采集多个组件多个节点的指标数据，并进行转换，然后以Prometheus规定的格式对外公开。

指标数据的转换规则可以查看github上的一些项目，要注意版本，也可以像我一样自己写，更可靠。

bigdata-exporter如何感知到采集目标？

除了部署ip不同，不同组件不同角色的指标对外端口、路径、内容（解析规则）也都不一样。
这里可以参考上面kubernetes_sd_config+relabel的方案，做得优雅一些：

1. 授予bigdata-exporter调用kubernetes app的能力，
2. 利用label和annotations进行筛选和信息传递，确定捕捉目标和途径。
3. 使用role代表解析内容的类型，根据role确定解析规则

```yaml
  labels:
    bigData.metrics.object: pod
  annotations:
    bigData.metrics/scrape: "true"
    bigData.metrics/scheme: "https"
    bigData.metrics/path: "/jmx"
    bigData.metrics/port: "29871"
    bigData.metrics/role: "hdfs-nn,common"
```

### 4. 告警设计示例

这里以*组*和*实例*两个维度为例，用groupId和instanceId表示。

#### 1) alertManager配置示例

以下是alertmanager的规则配置，有两个接收者，
其中 test.web.hook 指向自定义告警平台
default 是空白接收者，不做处理。
路由策略是根据groupId,instanceId分组，对节点磁盘使用率、kafka队列堆积两个组处理，instanceId还没有展开。

旧版本是用secret的data字段，需要将配置内容转成base64编码格式。
新版本直接用stringData字段。推荐用stringData字段配置。
其实只要看一下kube-prometheus的alertmanager-secret.yaml文件就知道怎么回事了。

使用data字段的配置方法：
写好config文件，以 alertmanager.yaml 命名（不能使用其他名称）。
执行以下命令,即可更新secret。

```shell
kubectl -n monitoring create secret generic alertmanager-main --from-file=alertmanager.yaml --dry-run -o yaml  |  kubectl -n=monitoring apply -f -
 
global:
  resolve_timeout: 5m
receivers:
  - name: 'default'
  - name: 'test.web.hook'
    webhook_configs:
      - url: 'http://alert-url'
route:
  receiver: 'default'
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 2h
  group_by: [groupId,instanceId]
  routes:
    - receiver: 'test.web.hook'
      continue: true
      match:
        groupId: node-disk-usage
    - receiver: 'test.web.hook'
      continue: true
      match:
        groupId: kafka-topic-highstore
 
```

#### 2) alertRule配置示例

组代表一个类型的所有目标：即所有节点
实例则代表具体的某个节点

disk-usage.yaml.ftl磁盘使用率告警配置示例如下：
注意：$为监控的磁盘路径，$为使用率阈值，需自行替换
labels中的userIds和receivers为传递给自定义告警平台的参数，以指导告警平台如何操作。
在这个任务中，我们的目标是组粒度的（所有节点），所以不需要设置instanceId。

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
   creationTimestamp: null
   labels:
      role: alert-rules
   name: node-disk-usage
   namespace: monitoring
spec:
   groups:
      - name: node-disk-usage
        rules:
           - alert: node-disk-usage
             expr: 100*(1-node_filesystem_avail_bytes{mountpoint="${path}"}/node_filesystem_size_bytes{mountpoint="${path}"} ) > ${thresholdValue}
             for: 1m
             labels:
                groupId: node-disk-usage
                userIds: super
                receivers: SMS
             annotations:
                title: "磁盘警告：节点{{$labels.instance}}的 ${path} 目录使用率已达到{{$value}}%"
                content: "磁盘警告：节点{{$labels.instance}}的 ${path} 目录使用率已达到{{$value}}%"
 
```

kafka-topic-highstore.yaml.ftl kafka队列消费堆积告警配置示例如下：
我们只关心个别队列的消费情况，所以这里的粒度为instance。
注意：$为队列名，$为消费组名称，$为堆积数量阈值

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  labels:
    role: alert-rules
  name: kafka-topic-highstore-${uniqueName}
  namespace: monitoring
spec:
  groups:
    - name: kafka-topic-highstore
      rules:
      - alert: kafka-topic-highstore-${uniqueName}
        expr: sum(kafka_consumergroup_lag{exporterType="kafka",consumergroup="${consumergroup}"}) > ${thresholdValue}
        for: 1m
        labels:
          groupId: kafka-topic-highstore
          instanceId: ${uniqueName}
          userIds: super
          receivers: SMS
        annotations:
          title: "KAFKA警告：消费组${consumergroup}的堆积数量达到:{{$value}}"
          content: "KAFKA警告：消费组${consumergroup}的堆积数量达到:{{$value}}"
 
```

## 三 其他

### 告警流程示例

这里以两个节点node1和node2配置了磁盘空间监控为例，空间使用到达阈值则触发告警。
（测试过程中可通过生成、删除指定体积的文件来控制空间占用）

其中配置项如下：

- 告警规则:node-disk-usage
  - for 为 1m
- 告警中心:alertManager
  - group_wait: 30s
  - group_interval: 5m
  - repeat_interval: 10m

收到的告警短信内容及时间线如下：

- 10:23:14收到第一次警报：
  node1于 10:22:44 进入异常
- 10:28:14收到第二次警报：
  node1于 10:22:44 进入异常
  node2于 10:24:44 进入异常
- 10:38:29收到第三次警报：
  node1于 10:22:44 进入异常
  node2于 10:24:44 进入异常
- 10:48:44收到第四次警报：
  node1于 10:22:44 进入异常
  node2于 10:24:44 进入异常
- 10:58:44收到第五次警报：恢复告警
  node1于 10:22:44 进入异常，并于10:55:44恢复
  node2于 10:24:44 进入异常，并于10:49:14恢复

总共收到5次短信，第1次是node1异常，
第2到4次是node1和node2都异常，因为属于同个分组group，所以合并发送。
第5次是已经恢复正常了。
根据短信内容和时间，整理出告警逻辑时间线如下：

1. node1等待for **1分钟** 后警报进入group
   node1记录异常时间为10:22:44，实际异常状态至少在10:22:44的一分钟前
2. group等待group_wait **30s** 后发送第一次告警
   firing:node1
3. node2等待for **1分钟** 后警报进入group
   node2记录异常时间为10:24:44，实际异常状态至少在10:24:44的一分钟前
   此时group中有两个异常目标node1和node2
4. group等待group_interval **5m** 后发送第二次告警
   firing:node1,node2
   注意：因为group发生了变化，所以这里用的是group_interval
5. group等待repeat_interval **10m** 后发送第三次告警
   firing:node1,node2
   注意：因为group没有变化，属于重复告警，用的是repeat_interval
6. group等待repeat_interval **10m** 后发送第四次告警
   firing:node1,node2
   同上一次
7. 第四次告警后的 前5分钟： node2恢复正常
8. 第四次告警后的 后5分钟： node1恢复正常
9. group等待repeat_interval **10m** 后发送第五次告警
   resolved:node1,node2
   注意，这里node1,node2都恢复正常用的也是repeat_interval

综上：

- for
  是告警规则个体的监控配置，用来衡量服务多久检测不通过才算异常
- group_wait 初次发送告警的等待时间
  用于group创建后的等待，这个值通常设置较小，在几分钟以内
- group_interval 同一个组其他新发生的告警发送时间间隔
  是group内容发生变化后的告警间隔
- repeat_interval 重复发送同一个告警的时间间隔
  group内容没有变化且上一次发生成功时用的发生间隔

需要注意，恢复正常不属于group变化，用的是repeat_interval。
这有点反直觉，且个人认为不是很合理，不知道是不是测试有问题，也没有找到比较好的资料说明。
希望知道的可以指教一下。

### exporter的位置

exporter可以以sidecar的形式和原容器放在同一个pod内（1对1），也可以以独立部署的形式存在（1对1/1对多）。
这个视具体情况而定，技术上没什么不同，sidecar可以绑定生命周期，视为对原有组件的补充。独立部署则耦合度更低，更灵活。
像单节点的mysql，用sidecar则只需要1个pod，不会太复杂。
而如果像多节点的kafka集群，用独立部署则只需要一个exporter就可以实现对多个节点的采集监控。

这里出于减小耦合、节省资源的目的，我主要使用的是独立部署形式。

### 使用promtool检查指标格式是否正确

promtool 使用方法：

```shell
# 进入pod
 kubectl -n=monitoring exec -it prometheus-k8s-0  sh
# 查看帮助
promtool -h
# 检查指标格式
curl -s http://ip:9999/metrics | promtool check metrics
 
```

比方说 指标name、labelname不能使用小数点

### 使用port-forward临时提供Prometheus外部访问

```shell
# prometheus
nohup  kubectl port-forward --address 0.0.0.0 service/prometheus-k8s 19090:9090 -n=monitoring &
# grafana
nohup kubectl port-forward --address 0.0.0.0 service/grafana 13000:3000 -n=monitoring &
# alertmanager
nohup  kubectl port-forward --address 0.0.0.0 service/alertmanager-main 9093:9093 -n=monitoring &
 
```

用 `jobs -l` 可以查看

### kube-prometheus对arm的支持

目标是找到kube-prometheus用到的镜像的arm版本

可以使用 https://quay.io/ 搜索

以下是用到的镜像和各自对arm的支持情况。
注意对照自己使用的版本，很多镜像高版本都支持arm了

未标记（不支持）其实也是可以用，但不保证

quay.io/prometheus/prometheus:v2.11.0 支持arm（v2.10.0开始）
quay.io/prometheus/alertmanager:v0.18.0 支持arm（v0.17.0开始）
quay.io/coreos/kube-state-metrics:v1.8.0 未标记（不支持）
quay.io/coreos/kube-rbac-proxy:v0.4.1 未标记（不支持）
quay.io/prometheus/node-exporter:v0.18.1 支持arm（v0.18.0开始）
quay.io/coreos/prometheus-operator:v0.34.0 不支持arm（v0.39开始） 修改成使用0.39.0，0.39以后的prometheus要求k8s必须>=1.16
quay.io/coreos/configmap-reload:v0.0.1 未标记（不支持）
grafana/grafana:6.4.3 官方说支持arm，但其实不支持，有bug，见：https://bleepcoder.com/cn/grafana/501674494/docker-arm-images-doesn-t-work-since-v6-4-x

quay.io/coreos/k8s-prometheus-adapter-amd64:v0.5.0 未找到arm版本镜像
最新的官方版本已经改用 directxman12/k8s-prometheus-adapter:v0.8.4
而directxman12/k8s-prometheus-adapter:v0.5.0 开始支持arm
见：https://hub.docker.com/r/directxman12/k8s-prometheus-adapter/tags
