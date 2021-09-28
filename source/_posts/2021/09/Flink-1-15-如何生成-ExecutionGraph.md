---
title: Flink(1.15)如何生成 ExecutionGraph
date: 2021-09-27 16:11:40
tags:
---

本文将会讲述 JobGraph 是如何转换成 ExecutionGraph 的。当 JobGraph 从 client 端提交到 JobManager 端后，JobManager 会根据 JobGraph 生成对应的 ExecutionGraph，ExecutionGraph 是 Flink 作业调度时使用到的核心数据结构，它包含每一个并行的 task、每一个 intermediate stream 以及它们之间的关系，本篇将会详细分析一下 JobGraph 转换为 ExecutionGraph 的流程。

## Create ExecutionGraph 的整体流程

当用户向一个 Flink 集群提交一个作业后，JobManager 会接收到 Client 相应的请求，JobManager 会先做一些初始化相关的操作（也就是 JobGraph 到 ExecutionGraph 的转化），当这个转换完成后，才会根据 ExecutionGraph 真正在分布式环境中调度当前这个作业，而 JobManager 端处理的整体流程如下：

![](https://gitee.com/hxf88/imgrepo/raw/master/img/flinkJobmanager1.png)

