---
title: centos安装ntpdate命令
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-09 11:21:21
tags:
---

 添加wlnmp源

rpm -ivh http://mirrors.wlnmp.com/centos/wlnmp-release-centos.noarch.rpm



安装ntp服务

yum install wntp

ntpdate cn.pool.ntp.org

设置时区：

`timedatectl set-timezone Asia/Shanghai`
