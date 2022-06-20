---
title: >-
  Kubernetes健康检测probe errored: rpc error: code = DeadlineExceeded desc = context
  deadline exceed
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-15 11:03:25
tags:
---

说说为啥写本文
春节假前，生产环境（基于Kubernetes的PaaS平台OpenShift）出现使用健康检测探针报错，但应用Pod并未下线的情况，导致服务卡住（某一节点死锁，Service总是负载均衡到此节点）。

查了OpenShift官方文档对此并无提及，在 Kubernetes 官方仓库的 Issue列表 中有所收获，在这里简单记录下。（Kubernetes v1.15.12以上版本已解决）

简单说来，这可能是 Kubernetes 历史遗留的一个 Bug，不过值得肯定的是：问题根源在于Kubernetes对于健康检测方式不同，对于运行时的报错处理也不同，直接导致了健康检测的报错。

底层出错不应该影响上层，上层本应防住的为啥不防住呢？你说是吧。

健康检测基础知识
健康检测，顾名思义是对应用节点进行检测，判断该节点是否健康可提供服务。

在Kubernetes 提供了三种健康检测的探针(Probes):

Liveness Probe 存活探针，检测Pod状态是否正常，如不正常则删除Pod，由Deployment自动创建新Pod
Readiness Probe 就绪探针，检测Pod容器内应用服务是否可用，如不可用，从Service列表中移出，不再有流量进入
Startup Probe 启动探针，Kubernetes 1.18开始出现的新探针，适用于应用启动慢的服务使用，防止在服务正常启动前被Liveness Probe判定为不健康状态删除Pod，与减少Readiness Probes频繁失败的问题
这三种探针都有相同的三种检测方式，只不过它们对检测结果的处理不同。三者均包含：

exec 容器执行命令方式
httpGet HTTP GET请求方式
tcpSocket 创建套接字方式
这里就不继续展开了，参见文末官方文档地址吧。

问题描述
生产环境中，使用了相对灵活的 exec 容器执行命令: curl http://localhost:8188/actuator/health/readiness，作为就绪探针（Readiness Probe），每10秒检测一下服务状态，在某个节点负载请求时，发生节点死锁，命令执行超时无响应，超过超时时间探针报错，但此节点未从Service列表中移出，导致集群其它节点没有流量进入，服务处于不可用状态。

报错信息为 Readiness probe errored: rpc error: code = DeadlineExceeded desc = context deadline exceeded
------------------------------------------------
为什么会发生此问题？
参考了这个issue中某位热心网友提供的源码注释

即 exec 容器内执行命令的探针遇到错误时并未变更Pod的状态，导致仍在负载均衡的列表中；其他探针中将检测过程中遇到的所有错误，都算作检测失败，变更Pod状态。

解决思路
问题本身出现在容器运行时上，但是问题反映在Kubernetes健康检测时，所以最简单的解决办法是 使用其他检测方式，如 httpGet 或 tcpSocket。

除此之外，升级Kubernetes 版本至 v1.15.12以上也可以解决问题，当然，要去根的话，需要升级 Containerd 版本了，一般对应 Docker 版本变化即可（Docker 绑定了 Containerd 管理容器）。

看来docker v19.03.6没问题 😆
------------------------------------------------
Kubernetes v1.20以后移除Docker运行时这事和本文关系不大，因为错误出在底层Containerd上
我这边公司用的OpenShift对应的Kubernetes版本太低，Docker也不能升（平台运维团队是甲方……），所以只能改了httpGet方式检测，另外因为OpenShift限制了界面上的端口号，又改了Deployment的yaml才搞定……
------------------------------------------------
以上使用 httpGet方式，请求 http://localhost:8080/healthz，启动时间延迟3秒，容器启动3秒后，开始每隔3秒一次检测。

总结
使用第三方服务还是需要深入了解下它的机制、有没有什么坑等情况，以免出现碰到问题不知如何解决的被动局面。

路茫茫其修远兮，吾将上下而求所。

参考

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
https://github.com/kubernetes/kubernetes/issues/82987

