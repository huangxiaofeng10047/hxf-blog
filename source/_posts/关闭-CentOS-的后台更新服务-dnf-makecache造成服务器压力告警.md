---
title: 关闭 CentOS 的后台更新服务 dnf makecache造成服务器压力告警
date: 2021-09-01 09:55:53
tags:
- linux
categories: 
- 运维
---



客户现场发现cpu会异常飙升，查询/var/log/message,寻找原因 Aug 25 04:20:39 localhost systemd[1]: Starting dnf makecache...。

经过查看系统日志发现，`dnf-makecache.service`服务一直定期的更新元数据导致cpu告警。

<!--more-->

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901095800713.png" alt="image-20210901095800713" style="zoom:150%;" />

> 不太能理解的是 dnf 命令执行的时候每次都强制更新，为什么还要有个计划任务一直跑~

执行下面的命令关闭并禁用掉这个定时器。

-   systemctl stop dnf-makecache.timer
-   systemctl disable dnf-makecache.timer

```
[root@dev-node ~]# systemctl stop dnf-makecache.timer
[root@dev-node ~]# systemctl disable dnf-makecache.timer
Removed /etc/systemd/system/multi-user.target.wants/dnf-makecache.timer.
```

**外网也有人对此问题进行过反馈**

-   [https://bugzilla.redhat.com/show\_bug.cgi?id=1187111](https://bugzilla.redhat.com/show_bug.cgi?id=1187111)
