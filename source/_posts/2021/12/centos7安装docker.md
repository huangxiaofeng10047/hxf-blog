---
title: centos7安装docker
date: 2021-12-20 14:15:47
tags:
---

### centos7安装Docker全过程记录（无坑版教程）

## 一、安装前必读

在安装 Docker 之前，先说一下配置，我这里是Centos7 Linux 内核：官方建议 3.10 以上，3.8以上貌似也可。

注意：本文的命令使用的是 root 用户登录执行，不是 root 的话所有命令前面要加 `sudo`

**1.查看当前的内核版本**

uname \-r

![](https://ask.qcloudimg.com/http-save/yehe-6025150/jmntavffl8.png?imageView2/2/w/1620)

我这里是3.10 ，满足条件。

**2.使用 root 权限更新 yum 包（生产环境中此步操作需慎重，看自己情况，学习的话随便搞）**

yum \-y update

这个命令不是必须执行的，看个人情况，后面出现不兼容的情况的话就必须update了

注意 
yum \-y update：升级所有包同时也升级软件和系统内核； 
yum \-y upgrade：只升级所有包，不升级软件和系统内核

**3.卸载旧版本（如果之前安装过的话）**

yum remove docker  docker\-common docker\-selinux docker\-engine

![](https://ask.qcloudimg.com/http-save/yehe-6025150/u6lfsra7qn.png?imageView2/2/w/1620)

## 二、安装Docker的详细步骤

**1.安装需要的软件包， yum-util 提供yum-config-manager功能，另两个是devicemapper驱动依赖**

```shell
yum install -y yum-utils device-mapper-persistent-data lvm2


```

**2.设置 yum 源**

设置一个yum源，下面两个都可用

yum\-config\-manager \--add\-repo http://download.docker.com/linux/centos/docker\-ce.repo（中央仓库）

yum\-config\-manager \--add\-repo http://mirrors.aliyun.com/docker\-ce/linux/centos/docker\-ce.repo（阿里仓库）

3.选择docker版本并安装 （1）查看可用版本有哪些

```javascript
yum list docker-ce --showduplicates | sort -r
```

（2）选择一个版本并安装：`yum install docker-ce-版本号`

```javascript
yum -y install docker-ce-18.03.1.ce
```

出现下图说明安装成功

4.启动 Docker 并设置开机自启

systemctl start docker
systemctl enable docker

over！

本文参与[腾讯云自媒体分享计划](https://cloud.tencent.com/developer/support-plan)，欢迎正在阅读的你也加入，一起分享。
