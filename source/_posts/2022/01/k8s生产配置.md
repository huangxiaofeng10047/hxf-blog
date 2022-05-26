---
title: 添加readmore
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---

```
# 节点资源预留
enforce-node-allocatable: 'pods'
system-reserved: 'cpu=0.25,memory=200Mi'
kube-reserved: 'cpu=0.25,memory=1500Mi'

# POD驱逐，这个参数只支持内存和磁盘。

## 硬驱逐阈值
### 当节点上的可用资源降至保留值以下时，就会触发强制驱逐。强制驱逐会强制kill掉POD，不会等POD自动退出。
eviction-hard: 'memory.available<300Mi,nodefs.available<10%,imagefs.available<15%,nodefs.inodesFree<5%'

## 软驱逐阈值
### 以下四个参数配套使用，当节点上的可用资源少于这个值时但大于硬驱逐阈值时候，会等待eviction-soft-grace-period设置的时长；
### 等待中每10s检查一次，当最后一次检查还触发了软驱逐阈值就会开始驱逐，驱逐不会直接Kill POD，先发送停止信号给POD，然后等待eviction-max-pod-grace-period设置的时长；
### 在eviction-max-pod-grace-period时长之后，如果POD还未退出则发送强制kill POD"
eviction-soft: 'memory.available<500Mi,nodefs.available<50%,imagefs.available<50%,nodefs.inodesFree<10%'
eviction-soft-grace-period: 'memory.available=1m30s'
eviction-max-pod-grace-period: '30'
eviction-pressure-transition-period: '30s'
```